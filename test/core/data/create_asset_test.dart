import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/data/field_actions.dart';
import 'package:work_flow/core/data/field_repository.dart';
import 'package:work_flow/core/data/models.dart';
import 'package:work_flow/core/db/local_database.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/core/outbox/outbox_op.dart';
import 'package:work_flow/core/outbox/outbox_processor.dart';
import 'package:work_flow/core/outbox/outbox_store.dart';
import 'package:work_flow/core/photos/photo_service.dart';
import 'package:work_flow/core/sync/sync_applier.dart';
import 'package:work_flow/core/sync/sync_page.dart';

import '../../helpers/db.dart';

class MockTransport extends Mock implements OutboxTransport {}

class MockSession extends Mock implements SessionRefresher {}

const _model = AssetModel({
  'id': 'm1',
  'name': 'Amoladora',
  'trackingType': 'INDIVIDUAL',
  'requiresPhoto': true,
});

AssetDraft draft({String code = 'AM-100'}) => AssetDraft(
      model: _model,
      internalCode: code,
      holderType: 'LOCATION',
      holderId: 'loc-obrador',
      effectiveLocationId: 'loc-obrador',
      effectiveProjectId: 'p1',
      manufacturerBarcode: '7790001',
      serialNumber: '  ',
      conditionId: 'c-bueno',
    );

LocalPhoto photo(String id) =>
    LocalPhoto(id: id, path: '/tmp/$id.jpg', sizeBytes: 1234, takenAt: DateTime.utc(2026, 10, 24, 12));

void main() {
  late LocalDatabase local;
  late RecordStore records;
  late OutboxStore outbox;
  late FieldActions actions;
  late FieldRepository repo;

  setUp(() async {
    final (l, r, o) = await openTestDb();
    local = l;
    records = r;
    outbox = o;
    actions = FieldActions(outbox: outbox, onEnqueued: () {}, clock: () => DateTime.utc(2026, 10, 24, 12));
    repo = FieldRepository(records);
  });

  tearDown(() => local.close());

  test('encola el alta (PUT con id del teléfono) y después sus fotos', () async {
    final id = await actions.createAsset(draft(), photos: [photo('f1'), photo('f2')]);

    final ops = await outbox.list();
    expect(ops.map((o) => o.path), ['/inventory/assets/$id', '/attachments/f1', '/attachments/f2']);
    final put = ops.first;
    expect(put.method, 'PUT');
    expect(put.body, {
      'modelId': 'm1',
      'internalCode': 'AM-100',
      'initialHolder': {'type': 'LOCATION', 'id': 'loc-obrador'},
      'manufacturerBarcode': '7790001',
      'conditionId': 'c-bueno',
      'occurredAt': '2026-10-24T12:00:00.000Z',
    });
    final f1 = ops[1];
    expect(f1.kind, OutboxKind.attachment);
    expect(f1.parentId, id);
    expect(f1.body, containsPair('ownerType', 'ASSET'));
    expect(f1.body, containsPair('ownerId', id));
    expect(f1.body, containsPair('assetId', id));
  });

  test('el ítem aparece enseguida en el proyecto, marcado sin enviar', () async {
    final id = await actions.createAsset(draft());

    final inProject = await repo.projectAssets('p1');
    expect(inProject.map((a) => a.id), [id]);
    final a = inProject.single;
    expect(a.internalCode, 'AM-100');
    expect(a.holderType, 'LOCATION');
    expect(a.status, 'OPERATIONAL');
    expect(a.hasPendingChange, isTrue);
    expect(await repo.findByCode('7790001'), isNotNull);
  });

  test('la sync no lo borra mientras siga en la cola', () async {
    final id = await actions.createAsset(draft());
    final applier = SyncApplier(records, outbox);

    // Descarga completa: borra lo local y vuelve a aplicar lo pendiente.
    await applier.apply(
      const SyncPage(cursor: 'c1', hasMore: false, changes: {}, deleted: {}),
      purgeLocal: true,
    );

    expect((await repo.asset(id))?.internalCode, 'AM-100');
  });

  test('cuando llega de la API, reemplaza la fila optimista', () async {
    final id = await actions.createAsset(draft());
    // Ya enviado: sale de la cola y la sync trae el ítem real.
    await outbox.complete((await outbox.list()).single.seq!);
    await SyncApplier(records, outbox).apply(SyncPage(
      cursor: 'c2',
      hasMore: false,
      changes: {
        SyncSources.assets: [
          {'id': id, 'internalCode': 'AM-100', 'effectiveProjectId': 'p1', 'status': 'OPERATIONAL'},
        ],
      },
      deleted: const {},
    ));

    expect((await repo.asset(id))!.hasPendingChange, isFalse);
  });

  test('validación local: el código interno no se repite', () async {
    await actions.createAsset(draft(code: 'AM-100'));
    expect(await repo.internalCodeInUse('am-100 '), isTrue);
    expect(await repo.internalCodeInUse('AM-101'), isFalse);
  });

  group('409: el código ya existe', () {
    late MockTransport transport;
    late MockSession session;
    late OutboxProcessor processor;
    late List<(String, Map<String, dynamic>?)> sent;

    setUp(() {
      transport = MockTransport();
      session = MockSession();
      sent = [];
      when(() => session.ensureFresh()).thenAnswer((_) async => RefreshOutcome.ok);
      when(() => transport.fileExists(any())).thenAnswer((_) async => true);
      when(() => transport.upload(any(), any(), any())).thenAnswer((_) async => const TransportResponse(200));
      processor = OutboxProcessor(store: outbox, transport: transport, session: session);
    });

    test('queda como fallido visible, con sus fotos', () async {
      when(() => transport.send(any(), any(), body: any(named: 'body'))).thenAnswer(
        (_) async => const TransportResponse(409, {'message': 'Ya existe un ítem con ese código interno'}),
      );
      await actions.createAsset(draft(), photos: [photo('f1')]);

      final r = await processor.drain();

      expect(r.failed, 1);
      final failed = await outbox.list(statuses: {OutboxStatus.failed});
      expect(failed.map((o) => o.kind), [OutboxKind.request, OutboxKind.attachment]);
      expect(failed.first.errorStatus, 409);
      expect(failed.first.lastError, 'Ya existe un ítem con ese código interno');
    });

    test('corregir el código y reintentar: mismo id, código nuevo, fotos detrás', () async {
      var first = true;
      when(() => transport.send(any(), any(), body: any(named: 'body'))).thenAnswer((inv) async {
        final method = inv.positionalArguments[0] as String;
        final path = inv.positionalArguments[1] as String;
        sent.add(('$method $path', inv.namedArguments[#body] as Map<String, dynamic>?));
        if (path.startsWith('/inventory/assets/') && first) {
          first = false;
          return const TransportResponse(409, {'message': 'Ya existe un ítem con ese código interno'});
        }
        return const TransportResponse(200, {'data': {}, 'meta': {'created': true, 'uploadUrl': 'https://r2/x'}});
      });
      final id = await actions.createAsset(draft(code: 'AM-100'), photos: [photo('f1')]);
      await processor.drain();

      final failed = (await outbox.list()).first;
      final (body, patches, label) = FieldActions.withNewInternalCode(failed, 'AM-200');
      await outbox.retry(failed.seq!, body: body, patches: patches, label: label);
      sent.clear();
      final r = await processor.drain();

      expect(r.failed, 0);
      expect(await outbox.list(), isEmpty);
      expect(sent.map((s) => s.$1), [
        'PUT /inventory/assets/$id',
        'PUT /attachments/f1',
        'POST /attachments/f1/confirm',
      ]);
      expect(sent.first.$2!['internalCode'], 'AM-200');
      expect((await repo.asset(id))!.internalCode, 'AM-200');
    });
  });
}
