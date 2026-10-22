import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/db/local_database.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/core/outbox/outbox_op.dart';
import 'package:work_flow/core/outbox/outbox_processor.dart';
import 'package:work_flow/core/outbox/outbox_store.dart';

import '../../helpers/db.dart';

class MockTransport extends Mock implements OutboxTransport {}

class MockSession extends Mock implements SessionRefresher {}

OutboxOp fact(String id, {String? parentId, List<RecordPatch> patches = const []}) => OutboxOp(
      id: id,
      kind: OutboxKind.request,
      method: 'PUT',
      path: '/check-ins/$id',
      body: {'occurredAt': '2026-10-22T10:00:00.000Z', 'type': 'UP'},
      label: const OutboxLabel('opCheckInUp', {'name': 'Carlos'}),
      occurredAt: DateTime.utc(2026, 10, 22, 10),
      parentId: parentId,
      patches: patches,
    );

OutboxOp photo(String id, {required String parentId}) => OutboxOp(
      id: id,
      kind: OutboxKind.attachment,
      method: 'PUT',
      path: '/attachments/$id',
      body: {'ownerType': 'SUBMISSION', 'ownerId': parentId, 'mimeType': 'image/jpeg', 'sizeBytes': 10},
      label: const OutboxLabel('opPhoto', {'what': 'x'}),
      occurredAt: DateTime.utc(2026, 10, 22, 10),
      parentId: parentId,
      filePath: '/tmp/$id.jpg',
    );

TransportResponse ok({bool created = true, Map<String, dynamic> meta = const {}}) =>
    TransportResponse(200, {
      'data': {},
      'meta': {'created': created, ...meta},
    });

void main() {
  late LocalDatabase local;
  late OutboxStore store;
  late MockTransport transport;
  late MockSession session;
  late OutboxProcessor processor;
  late List<String> sent;

  setUp(() async {
    final (l, _, o) = await openTestDb();
    local = l;
    store = o;
    transport = MockTransport();
    session = MockSession();
    sent = [];
    when(() => session.ensureFresh()).thenAnswer((_) async => RefreshOutcome.ok);
    when(() => session.forceRefresh()).thenAnswer((_) async => RefreshOutcome.ok);
    when(() => transport.fileExists(any())).thenAnswer((_) async => true);
    processor = OutboxProcessor(store: store, transport: transport, session: session);
  });

  tearDown(() => local.close());

  void answer(TransportResponse Function(String method, String path) f) {
    when(() => transport.send(any(), any(), body: any(named: 'body'))).thenAnswer((inv) async {
      final method = inv.positionalArguments[0] as String;
      final path = inv.positionalArguments[1] as String;
      sent.add('$method $path');
      return f(method, path);
    });
  }

  group('orden', () {
    test('drena en el orden en que se encoló y vacía la cola', () async {
      answer((_, __) => ok());
      await store.enqueue([fact('a'), fact('b')]);
      await store.enqueue([fact('c')]);

      final r = await processor.drain();

      expect(sent, ['PUT /check-ins/a', 'PUT /check-ins/b', 'PUT /check-ins/c']);
      expect(r.sent, 3);
      expect(r.stop, DrainStop.empty);
      expect((await store.currentCounts()).pending, 0);
    });

    test('refresca la sesión antes de drenar (contrato §2)', () async {
      answer((_, __) => ok());
      await store.enqueue([fact('a')]);

      await processor.drain();

      verifyInOrder([
        () => session.ensureFresh(),
        () => transport.send('PUT', '/check-ins/a', body: any(named: 'body')),
      ]);
    });

    test('cola vacía: ni refresca ni llama a la API', () async {
      final r = await processor.drain();
      expect(r.stop, DrainStop.empty);
      verifyNever(() => session.ensureFresh());
    });
  });

  group('idempotencia', () {
    test('created: false (ya estaba) también sale de la cola', () async {
      answer((_, __) => ok(created: false));
      await store.enqueue([fact('a')]);

      final r = await processor.drain();

      expect(r.sent, 1);
      expect(await store.list(), isEmpty);
    });

    test('dos drenados a la vez mandan cada hecho una sola vez', () async {
      answer((_, __) => ok());
      await store.enqueue([fact('a'), fact('b')]);

      await Future.wait([processor.drain(), processor.drain(), processor.drain()]);

      expect(sent, ['PUT /check-ins/a', 'PUT /check-ins/b']);
    });

    test('el reintento usa el mismo id', () async {
      var calls = 0;
      answer((_, __) => ++calls == 1 ? const TransportResponse(503) : ok());
      await store.enqueue([fact('a')]);

      await processor.drain();
      await processor.drain();

      expect(sent, ['PUT /check-ins/a', 'PUT /check-ins/a']);
      expect(await store.list(), isEmpty);
    });
  });

  group('reintentos', () {
    test('5xx corta el drenado y deja todo pendiente en orden', () async {
      answer((_, path) => path.endsWith('/b') ? const TransportResponse(500) : ok());
      await store.enqueue([fact('a'), fact('b'), fact('c')]);

      final r = await processor.drain();

      expect(r.stop, DrainStop.offline);
      expect(sent, ['PUT /check-ins/a', 'PUT /check-ins/b']);
      final left = await store.list();
      expect(left.map((o) => o.id), ['b', 'c']);
      expect(left.first.status, OutboxStatus.pending);
      expect(left.first.attempts, 1);
    });

    test('sin red: se reintenta después sin perder nada', () async {
      when(() => transport.send(any(), any(), body: any(named: 'body')))
          .thenThrow(const OfflineException());
      await store.enqueue([fact('a'), fact('b')]);

      final r = await processor.drain();

      expect(r.stop, DrainStop.offline);
      expect((await store.currentCounts()).pending, 2);
    });

    test('sin red para refrescar: no manda nada', () async {
      when(() => session.ensureFresh()).thenAnswer((_) async => RefreshOutcome.offline);
      await store.enqueue([fact('a')]);

      final r = await processor.drain();

      expect(r.stop, DrainStop.offline);
      verifyNever(() => transport.send(any(), any(), body: any(named: 'body')));
    });

    test('401: refresca y reintenta una vez', () async {
      var calls = 0;
      answer((_, __) => ++calls == 1 ? const TransportResponse(401) : ok());
      await store.enqueue([fact('a')]);

      final r = await processor.drain();

      expect(r.sent, 1);
      verify(() => session.forceRefresh()).called(1);
    });

    test('401 y el refresh rechazado: sesión vencida, la cola se conserva', () async {
      answer((_, __) => const TransportResponse(401));
      when(() => session.forceRefresh()).thenAnswer((_) async => RefreshOutcome.expired);
      await store.enqueue([fact('a')]);

      final r = await processor.drain();

      expect(r.stop, DrainStop.sessionExpired);
      expect((await store.currentCounts()).pending, 1);
    });
  });

  group('fallidos', () {
    test('4xx queda como fallido visible y se sigue con el siguiente (RN-25)', () async {
      answer((_, path) => path.endsWith('/a')
          ? const TransportResponse(400, {'message': 'El proyecto no existe'})
          : ok());
      await store.enqueue([fact('a'), fact('b')]);

      final r = await processor.drain();

      expect(r.failed, 1);
      expect(r.sent, 1);
      final failed = await store.list(statuses: {OutboxStatus.failed});
      expect(failed.single.id, 'a');
      expect(failed.single.lastError, 'El proyecto no existe');
      expect(failed.single.errorStatus, 400);
      expect((await store.currentCounts()).failed, 1);
    });

    test('si falla el hecho, sus fotos fallan con él', () async {
      answer((_, __) => const TransportResponse(422, {'message': ['lines must be an array']}));
      await store.enqueue([fact('v'), photo('p1', parentId: 'v'), photo('p2', parentId: 'v')]);

      await processor.drain();

      final failed = await store.list(statuses: {OutboxStatus.failed});
      expect(failed.map((o) => o.id), ['v', 'p1', 'p2']);
      expect(sent, ['PUT /check-ins/v']);
    });

    test('reintentar un fallido lo vuelve a la cola con el mismo id', () async {
      var calls = 0;
      answer((_, __) => ++calls == 1 ? const TransportResponse(403, {'message': 'No'}) : ok());
      await store.enqueue([fact('a')]);
      await processor.drain();
      final seq = (await store.list()).single.seq!;

      await store.retry(seq);
      await processor.drain();

      expect(sent, ['PUT /check-ins/a', 'PUT /check-ins/a']);
      expect(await store.list(), isEmpty);
    });

    test('remito ya recibido por otro: queda como aviso (RN-27)', () async {
      answer((_, __) => ok(created: true, meta: {'discarded': true, 'message': 'Ya confirmado'}));
      await store.enqueue([fact('r')]);

      final r = await processor.drain();

      expect(r.discarded, 1);
      final notice = (await store.list()).single;
      expect(notice.status, OutboxStatus.discarded);
      expect(notice.lastError, 'Ya confirmado');
    });
  });

  group('fotos (contrato §5)', () {
    test('registrar → subir a R2 → confirmar', () async {
      answer((method, path) => method == 'PUT'
          ? const TransportResponse(200, {
              'data': {},
              'meta': {'uploadUrl': 'https://r2/x'},
            })
          : ok());
      when(() => transport.upload(any(), any(), any())).thenAnswer((_) async => const TransportResponse(200));
      await store.enqueue([photo('p', parentId: 'v')]);

      final r = await processor.drain();

      expect(r.sent, 1);
      expect(sent, ['PUT /attachments/p', 'POST /attachments/p/confirm']);
      verify(() => transport.upload('https://r2/x', '/tmp/p.jpg', 'image/jpeg')).called(1);
    });

    test('ya subida (uploadUrl null): solo confirma', () async {
      answer((_, __) => ok(meta: {'uploadUrl': null}));
      await store.enqueue([photo('p', parentId: 'v')]);

      await processor.drain();

      verifyNever(() => transport.upload(any(), any(), any()));
      expect(sent, ['PUT /attachments/p', 'POST /attachments/p/confirm']);
    });

    test('confirm 409 (todavía no llegó a R2): se reintenta', () async {
      answer((method, _) => method == 'POST' ? const TransportResponse(409) : ok(meta: {'uploadUrl': 'u'}));
      when(() => transport.upload(any(), any(), any())).thenAnswer((_) async => const TransportResponse(200));
      await store.enqueue([photo('p', parentId: 'v')]);

      final r = await processor.drain();

      expect(r.stop, DrainStop.offline);
      expect((await store.list()).single.status, OutboxStatus.pending);
    });

    test('la URL firmada venció (R2 403): se reintenta registrando de nuevo', () async {
      answer((_, __) => ok(meta: {'uploadUrl': 'u'}));
      when(() => transport.upload(any(), any(), any())).thenAnswer((_) async => const TransportResponse(403));
      await store.enqueue([photo('p', parentId: 'v')]);

      await processor.drain();

      expect((await store.list()).single.status, OutboxStatus.pending);
      expect(sent, ['PUT /attachments/p']);
    });

    test('la foto ya no está en el teléfono: fallida', () async {
      when(() => transport.fileExists(any())).thenAnswer((_) async => false);
      await store.enqueue([photo('p', parentId: 'v')]);

      await processor.drain();

      final op = (await store.list()).single;
      expect(op.status, OutboxStatus.failed);
      expect(op.lastError, 'photo_missing');
    });
  });

  group('cambios optimistas', () {
    test('solo los hechos pendientes aportan sus cambios', () async {
      answer((_, path) => path.endsWith('/a') ? const TransportResponse(400) : const TransportResponse(500));
      await store.enqueue([
        fact('a', patches: [const RecordPatch(source: 'assets', id: 'x', fields: {'status': 'LOST'})]),
        fact('b', patches: [const RecordPatch(source: 'assets', id: 'y', fields: {'status': 'DAMAGED'})]),
      ]);

      await processor.drain();

      final patches = await store.pendingPatches(local.db);
      expect(patches.map((p) => p.id), ['y']);
    });
  });
}
