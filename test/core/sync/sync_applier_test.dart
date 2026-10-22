import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/db/local_database.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/core/outbox/outbox_op.dart';
import 'package:work_flow/core/outbox/outbox_store.dart';
import 'package:work_flow/core/sync/sync_applier.dart';
import 'package:work_flow/core/sync/sync_engine.dart';
import 'package:work_flow/core/sync/sync_page.dart';

import '../../helpers/db.dart';

class MockFetcher extends Mock implements SyncFetcher {}

SyncPage page({
  String cursor = 'c1',
  bool hasMore = false,
  Map<String, List<Map<String, dynamic>>> changes = const {},
  Map<String, List<String>> deleted = const {},
}) =>
    SyncPage(cursor: cursor, hasMore: hasMore, changes: changes, deleted: deleted);

Map<String, dynamic> asset(String id, {String status = 'OPERATIONAL', String? projectId}) => {
      'id': id,
      'internalCode': id.toUpperCase(),
      'status': status,
      'effectiveProjectId': projectId,
    };

void main() {
  late LocalDatabase local;
  late RecordStore records;
  late OutboxStore outbox;
  late SyncApplier applier;

  setUp(() async {
    final (l, r, o) = await openTestDb();
    local = l;
    records = r;
    outbox = o;
    applier = SyncApplier(records, outbox);
  });

  tearDown(() => local.close());

  group('SyncApplier', () {
    test('upsert por id: inserta y actualiza sin duplicar', () async {
      await applier.apply(page(changes: {
        'assets': [asset('a1'), asset('a2')],
      }));
      // Filas repetidas a propósito (margen de solapamiento del cursor).
      await applier.apply(page(cursor: 'c2', changes: {
        'assets': [asset('a1', status: 'DAMAGED'), asset('a2')],
      }));

      final rows = await records.all('assets');
      expect(rows, hasLength(2));
      expect((await records.get('assets', 'a1'))!['status'], 'DAMAGED');
    });

    test('borra los ids de deleted', () async {
      await applier.apply(page(changes: {
        'locations': [
          {'id': 'l1', 'name': 'Almacén'},
          {'id': 'l2', 'name': 'Obrador'},
        ],
      }));
      await applier.apply(page(cursor: 'c2', deleted: {
        'locations': ['l1'],
      }));

      expect((await records.all('locations')).map((r) => r['id']), ['l2']);
    });

    test('guarda el cursor de cada página', () async {
      await applier.apply(page(cursor: 'abc'));
      expect(await records.getValue(KvKeys.syncCursor), 'abc');
    });

    test('ignora fuentes que el teléfono no usa', () async {
      final touched = await applier.apply(page(changes: {
        'quotes': [
          {'id': 'q1'},
        ],
        'projects': [
          {'id': 'p1', 'name': 'Mina'},
        ],
      }));
      expect(touched, {'projects'});
      expect(await records.count('quotes'), 0);
    });

    test('indexa por proyecto para listar los ítems del proyecto', () async {
      await applier.apply(page(changes: {
        'assets': [asset('a1', projectId: 'p1'), asset('a2', projectId: 'p2')],
      }));
      final inP1 = await records.all('assets', projectId: 'p1');
      expect(inP1.map((r) => r['id']), ['a1']);
    });

    test('vuelve a aplicar los cambios de lo que sigue en la cola', () async {
      await applier.apply(page(changes: {
        'assets': [asset('a1')],
      }));
      await outbox.enqueue([
        OutboxOp(
          id: 'm1',
          kind: OutboxKind.request,
          method: 'PUT',
          path: '/inventory/asset-movements/m1',
          label: const OutboxLabel('opMove'),
          occurredAt: DateTime.utc(2026),
          patches: const [
            RecordPatch(source: 'assets', id: 'a1', fields: {'holderId': 'box', 'holderType': 'ASSET'}),
          ],
        ),
      ]);
      // La API todavía no recibió el movimiento: la sync trae el ítem viejo.
      await applier.apply(page(cursor: 'c2', changes: {
        'assets': [asset('a1')],
      }));

      final a1 = (await records.get('assets', 'a1'))!;
      expect(a1['holderId'], 'box');
      expect(a1['internalCode'], 'A1');
    });

    test('una descarga completa borra lo creado en el teléfono', () async {
      await records.transaction((txn) => records.applyPatch(
            txn,
            const RecordPatch(source: 'submissions', id: 's1', fields: {'_local': true, 'type': 'DAILY_LOG'}),
          ));
      await applier.apply(page(changes: {
        'submissions': [
          {'id': 's2', 'type': 'DAILY_LOG'},
        ],
      }), purgeLocal: true);

      expect((await records.all('submissions')).map((r) => r['id']), ['s2']);
    });
  });

  group('SyncEngine', () {
    late MockFetcher fetcher;
    late SyncEngine engine;

    setUp(() {
      fetcher = MockFetcher();
      engine = SyncEngine(
        fetcher: fetcher,
        applier: applier,
        store: records,
        clock: () => DateTime.utc(2026, 10, 22, 12),
      );
    });

    test('pagina mientras hasMore y pasa el cursor recibido', () async {
      when(() => fetcher.fetch(null)).thenAnswer((_) async => page(
            cursor: 'p1',
            hasMore: true,
            changes: {
              'assets': [asset('a1')],
            },
          ));
      when(() => fetcher.fetch('p1')).thenAnswer((_) async => page(
            cursor: 'p2',
            hasMore: true,
            changes: {
              'assets': [asset('a2')],
            },
          ));
      when(() => fetcher.fetch('p2')).thenAnswer((_) async => page(cursor: 'p3'));

      final r = await engine.pull();

      expect(r.pages, 3);
      verifyInOrder([
        () => fetcher.fetch(null),
        () => fetcher.fetch('p1'),
        () => fetcher.fetch('p2'),
      ]);
      expect(await records.count('assets'), 2);
      expect(await records.getValue(KvKeys.syncCursor), 'p3');
      expect(await records.getValue(KvKeys.lastSyncAt), '2026-10-22T12:00:00.000Z');
    });

    test('la próxima sync arranca desde el cursor guardado (delta)', () async {
      when(() => fetcher.fetch(null)).thenAnswer((_) async => page(cursor: 'k1'));
      when(() => fetcher.fetch('k1')).thenAnswer((_) async => page(cursor: 'k2'));

      await engine.pull();
      await engine.pull();

      verify(() => fetcher.fetch(null)).called(1);
      verify(() => fetcher.fetch('k1')).called(1);
    });

    test('reset fuerza una descarga completa', () async {
      when(() => fetcher.fetch(any())).thenAnswer((_) async => page(cursor: 'k1'));
      await engine.pull();
      await engine.reset();
      await engine.pull();

      verify(() => fetcher.fetch(null)).called(2);
    });

    test('tope de páginas ante un servidor que nunca termina', () async {
      final capped = SyncEngine(fetcher: fetcher, applier: applier, store: records, maxPages: 3);
      when(() => fetcher.fetch(any())).thenAnswer((_) async => page(cursor: 'x', hasMore: true));

      final r = await capped.pull();

      expect(r.pages, 3);
    });

    test('un error de red deja el cursor de la última página aplicada', () async {
      when(() => fetcher.fetch(null)).thenAnswer((_) async => page(cursor: 'p1', hasMore: true));
      when(() => fetcher.fetch('p1')).thenThrow(Exception('offline'));

      await expectLater(engine.pull(), throwsException);
      expect(await records.getValue(KvKeys.syncCursor), 'p1');
    });
  });
}
