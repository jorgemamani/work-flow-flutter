// Flujo de campo contra una API real (no corre en CI).
//
//   API_BASE_URL=http://localhost:3103 flutter test test/integration
//
// Necesita la empresa demo del seed (CUIT 30-12345678-9, DNI 30111222,
// PIN 1234) y un remito EN TRÁNSITO hacia su proyecto.
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/auth/session_manager.dart';
import 'package:work_flow/core/auth/token_store.dart';
import 'package:work_flow/core/data/field_actions.dart';
import 'package:work_flow/core/data/field_repository.dart';
import 'package:work_flow/core/ids.dart';
import 'package:work_flow/core/network/api_client.dart';
import 'package:work_flow/core/network/api_paths.dart';
import 'package:work_flow/core/network/auth_interceptor.dart';
import 'package:work_flow/core/network/connectivity_service.dart';
import 'package:work_flow/core/network/offline_guard_interceptor.dart';
import 'package:work_flow/core/outbox/outbox_processor.dart';
import 'package:work_flow/core/photos/photo_service.dart';
import 'package:work_flow/core/sync/sync_applier.dart';
import 'package:work_flow/core/sync/sync_engine.dart';

import '../helpers/db.dart';

class MockConnectivity extends Mock implements Connectivity {}

class MemoryTokens implements TokenStore {
  SessionTokens? value;

  @override
  Future<void> clear() async => value = null;

  @override
  Future<SessionTokens?> read() async => value;

  @override
  Future<void> write(SessionTokens tokens) async => value = tokens;
}

// JPEG mínimo válido (1x1).
const _jpeg = [
  0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01, //
  0x00, 0x01, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43, 0x00, 0x08, 0x06, 0x06, 0x07, 0x06, 0x05, 0x08,
  0x07, 0x07, 0x07, 0x09, 0x09, 0x08, 0x0A, 0x0C, 0x14, 0x0D, 0x0C, 0x0B, 0x0B, 0x0C, 0x19, 0x12,
  0x13, 0x0F, 0x14, 0x1D, 0x1A, 0x1F, 0x1E, 0x1D, 0x1A, 0x1C, 0x1C, 0x20, 0x24, 0x2E, 0x27, 0x20,
  0x22, 0x2C, 0x23, 0x1C, 0x1C, 0x28, 0x37, 0x29, 0x2C, 0x30, 0x31, 0x34, 0x34, 0x34, 0x1F, 0x27,
  0x39, 0x3D, 0x38, 0x32, 0x3C, 0x2E, 0x33, 0x34, 0x32, 0xFF, 0xC0, 0x00, 0x0B, 0x08, 0x00, 0x01,
  0x00, 0x01, 0x01, 0x01, 0x11, 0x00, 0xFF, 0xC4, 0x00, 0x14, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x09, 0xFF, 0xC4, 0x00, 0x14,
  0x10, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0xFF, 0xDA, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3F, 0x00, 0x2A, 0x9F, 0xFF, 0xD9,
];

void main() {
  final base = Platform.environment['API_BASE_URL'];

  test('subida, recepción con faltante y dañado con foto y verificación con foto: sin señal y después con señal', () async {
    final (local, records, outbox) = await openTestDb();
    final mockConn = MockConnectivity();
    when(() => mockConn.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => mockConn.onConnectivityChanged).thenAnswer((_) => const Stream.empty());
    final connectivity = ConnectivityService(connectivity: mockConn);
    await connectivity.start(simulatedOffline: false);

    final opts = BaseOptions(baseUrl: '$base${ApiPaths.prefix}', headers: {'Content-Type': 'application/json'});
    final guard = OfflineGuardInterceptor(connectivity);
    final session = SessionManager(authDio: Dio(opts)..interceptors.add(guard), tokens: MemoryTokens());
    final apiDio = Dio(opts);
    apiDio.interceptors
      ..add(guard)
      ..add(AuthInterceptor(session, apiDio));
    final api = ApiClient(apiDio, Dio()..interceptors.add(guard));
    final engine = SyncEngine(fetcher: api, applier: SyncApplier(records, outbox), store: records);
    final processor = OutboxProcessor(store: outbox, transport: api, session: session);
    final actions = FieldActions(outbox: outbox, onEnqueued: () {});
    final repo = FieldRepository(records);

    // 1. Login de campo y descarga inicial.
    await session.loginField(cuit: '30-12345678-9', documentNumber: '30111222', pin: '1234');
    final me = await api.get(ApiPaths.me) as Map<String, dynamic>;
    final employeeId = (me['employee'] as Map)['id'] as String;
    await engine.pull();
    final project = (await repo.projects()).first;
    // Arranca abajo, como quien llega a la mina.
    if ((me['employee'] as Map)['onSite'] == true) {
      await actions.checkIn(projectId: project.id, type: 'DOWN', employeeId: employeeId, self: true, employeeName: 'Carlos');
      expect((await processor.drain()).sent, 1);
    }
    final remitos = await repo.incomingRemitos(project.id);
    expect(remitos, isNotEmpty, reason: 'hace falta un remito en tránsito hacia ${project.name}');
    final remito = remitos.first;
    final items = await repo.remitoItems(remito.id);
    final assets = await repo.assetsById();

    // 2. Sin señal.
    connectivity.setSimulatedOffline(true);
    final tmp = await Directory.systemTemp.createTemp('wf');
    LocalPhoto newPhoto(String name) {
      final f = File('${tmp.path}/$name.jpg')..writeAsBytesSync(_jpeg);
      return LocalPhoto(id: newId(), path: f.path, sizeBytes: f.lengthSync(), takenAt: DateTime.now());
    }

    // RN-02: la API acepta la recepción de quien figura arriba en el proyecto,
    // así que la subida va primero en la cola (la app la ofrece antes de recibir).
    await actions.checkIn(
      projectId: project.id,
      type: 'UP',
      employeeId: employeeId,
      self: true,
      employeeName: 'Carlos',
    );
    final units = [for (final i in items) if (i.assetId != null) i];
    final lines = [
      for (final i in items)
        ReceptionLineInput(
          item: i,
          quantityReceived: i.assetId == null ? i.quantitySent - 2 : null,
        ),
    ];
    lines.firstWhere((l) => l.item.id == units[0].id).result = ReceptionResult.missing;
    final damaged = lines.firstWhere((l) => l.item.id == units[1].id)
      ..result = ReceptionResult.damaged
      ..notes = 'Golpe en la carcasa';
    damaged.photos.add(newPhoto('damaged'));
    await actions.receiveRemito(remito: remito, lines: lines, notes: 'Prueba integración');

    final verifyAsset = assets[units[2].assetId]!;
    final vline = VerificationLineInput(asset: verifyAsset)..photos.add(newPhoto('verif'));
    await actions.submitVerification(projectId: project.id, lines: [vline], notes: 'Control de llegada');

    expect((await outbox.currentCounts()).pending, 5);
    // Optimista: el remito ya figura recibido en el teléfono.
    expect((await repo.remito(remito.id))!.status, 'RECEIVED_WITH_DIFFERENCES');
    final offline = await processor.drain();
    expect(offline.stop, DrainStop.offline);
    expect((await outbox.currentCounts()).pending, 5);

    // 3. Vuelve la señal: refresh, cola en orden, sync.
    connectivity.setSimulatedOffline(false);
    final report = await processor.drain();
    expect(report.failed, 0, reason: [for (final o in await outbox.list()) '${o.label.key} ${o.status.name} ${o.errorStatus} ${o.lastError}'].join('\n'));
    expect(report.sent, 5);
    await engine.pull();

    // 4. Los datos están en la API.
    final r = await api.get('/remitos/${remito.id}') as Map<String, dynamic>;
    expect(r['status'], 'RECEIVED_WITH_DIFFERENCES');
    final photos = await api.get('/attachments', query: {'ownerType': 'REMITO', 'ownerId': remito.id}) as List;
    expect(photos.map((p) => (p as Map)['uploadStatus']), contains('UPLOADED'));
    final me2 = await api.get(ApiPaths.me) as Map<String, dynamic>;
    expect((me2['employee'] as Map)['onSite'], true);
    final verifs = await repo.submissions(type: 'VERIFICATION');
    expect(verifs.where((s) => !s.isLocal), isNotEmpty);

    await local.close();
  }, skip: base == null ? 'API_BASE_URL no definida' : false, timeout: const Timeout(Duration(minutes: 2)));
}
