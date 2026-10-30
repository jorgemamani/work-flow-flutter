import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:work_flow/core/auth/profile.dart';
import 'package:work_flow/core/auth/profile_repository.dart';
import 'package:work_flow/core/db/record_store.dart';
import 'package:work_flow/core/network/connectivity_service.dart';
import 'package:work_flow/core/outbox/outbox_processor.dart';
import 'package:work_flow/core/outbox/outbox_store.dart';
import 'package:work_flow/core/sync/sync_coordinator.dart';
import 'package:work_flow/core/sync/sync_engine.dart';

class MockConnectivity extends Mock implements ConnectivityService {}

class MockOutbox extends Mock implements OutboxStore {}

class MockProcessor extends Mock implements OutboxProcessor {}

class MockEngine extends Mock implements SyncEngine {}

class MockRecords extends Mock implements RecordStore {}

class MockProfiles extends Mock implements ProfileRepository {}

void main() {
  late MockConnectivity connectivity;
  late MockOutbox outbox;
  late MockProcessor processor;
  late MockEngine engine;
  late MockRecords records;
  late MockProfiles profiles;

  SyncCoordinator build() => SyncCoordinator(
        connectivity: connectivity,
        outbox: outbox,
        processor: processor,
        engine: engine,
        store: records,
        profiles: profiles,
      );

  setUp(() {
    connectivity = MockConnectivity();
    outbox = MockOutbox();
    processor = MockProcessor();
    engine = MockEngine();
    records = MockRecords();
    profiles = MockProfiles();
    when(() => connectivity.isOnline).thenReturn(true);
    when(() => connectivity.simulatedOffline).thenReturn(false);
    when(() => outbox.currentCounts()).thenAnswer((_) async => const OutboxCounts());
    when(() => records.getValue(KvKeys.lastSyncAt)).thenAnswer((_) async => '2026-10-22T12:00:00.000Z');
    when(() => engine.pull()).thenAnswer((_) async => const SyncResult(pages: 1, touched: {}));
    when(() => engine.reset()).thenAnswer((_) async {});
    when(() => profiles.fetch()).thenAnswer((_) async => const Profile({}));
  });

  blocTest<SyncCoordinator, SyncStatus>(
    'con señal: drena la cola y después baja cambios',
    setUp: () => when(() => processor.drain())
        .thenAnswer((_) async => const DrainReport(sent: 2, stop: DrainStop.empty)),
    build: build,
    act: (c) => c.syncNow(),
    expect: () => [
      isA<SyncStatus>().having((s) => s.syncing, 'syncing', true),
      isA<SyncStatus>()
          .having((s) => s.syncing, 'syncing', false)
          .having((s) => s.lastSyncAt, 'lastSyncAt', DateTime.utc(2026, 10, 22, 12)),
    ],
    verify: (_) {
      verifyInOrder([() => processor.drain(), () => engine.pull(), () => profiles.fetch()]);
      verifyNever(() => engine.reset());
    },
  );

  blocTest<SyncCoordinator, SyncStatus>(
    'si algo falló, baja todo de nuevo para revertir lo optimista',
    setUp: () => when(() => processor.drain())
        .thenAnswer((_) async => const DrainReport(sent: 1, failed: 1, stop: DrainStop.empty)),
    build: build,
    act: (c) => c.syncNow(),
    verify: (_) => verifyInOrder([() => engine.reset(), () => engine.pull()]),
  );

  blocTest<SyncCoordinator, SyncStatus>(
    'si la cola no terminó de salir, no baja cambios',
    setUp: () => when(() => processor.drain())
        .thenAnswer((_) async => const DrainReport(stop: DrainStop.offline)),
    build: build,
    act: (c) => c.syncNow(),
    expect: () => [
      isA<SyncStatus>().having((s) => s.syncing, 'syncing', true),
      isA<SyncStatus>().having((s) => s.lastError, 'lastError', 'offline'),
    ],
    verify: (_) => verifyNever(() => engine.pull()),
  );

  blocTest<SyncCoordinator, SyncStatus>(
    'refresh rechazado: sesión vencida',
    setUp: () => when(() => processor.drain())
        .thenAnswer((_) async => const DrainReport(stop: DrainStop.sessionExpired)),
    build: build,
    act: (c) => c.syncNow(),
    expect: () => [
      isA<SyncStatus>().having((s) => s.syncing, 'syncing', true),
      isA<SyncStatus>().having((s) => s.sessionExpired, 'sessionExpired', true),
    ],
  );

  blocTest<SyncCoordinator, SyncStatus>(
    'sin señal no intenta nada',
    setUp: () => when(() => connectivity.isOnline).thenReturn(false),
    build: build,
    act: (c) => c.syncNow(),
    expect: () => <SyncStatus>[],
    verify: (_) => verifyNever(() => processor.drain()),
  );

  blocTest<SyncCoordinator, SyncStatus>(
    'al volver la señal, sincroniza solo',
    setUp: () {
      final online = StreamController<bool>.broadcast();
      when(() => connectivity.onlineChanges).thenAnswer((_) => online.stream);
      when(() => outbox.counts).thenAnswer((_) => const Stream.empty());
      when(() => processor.drain())
          .thenAnswer((_) async => const DrainReport(sent: 1, stop: DrainStop.empty));
      Future<void>.delayed(const Duration(milliseconds: 20), () => online.add(true));
    },
    build: build,
    act: (c) async {
      await c.start();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      await c.close();
    },
    verify: (_) => verify(() => processor.drain()).called(1),
  );
}
