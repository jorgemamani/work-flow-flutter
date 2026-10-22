import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'config/environment/environment.dart';
import 'core/auth/profile_repository.dart';
import 'core/auth/session_manager.dart';
import 'core/auth/token_store.dart';
import 'core/data/field_actions.dart';
import 'core/data/field_repository.dart';
import 'core/db/local_database.dart';
import 'core/db/record_store.dart';
import 'core/network/api_client.dart';
import 'core/network/api_paths.dart';
import 'core/network/auth_interceptor.dart';
import 'core/network/connectivity_service.dart';
import 'core/network/offline_guard_interceptor.dart';
import 'core/outbox/outbox_processor.dart';
import 'core/outbox/outbox_store.dart';
import 'core/photos/photo_service.dart';
import 'core/sync/sync_applier.dart';
import 'core/sync/sync_coordinator.dart';
import 'core/sync/sync_engine.dart';
import 'features/auth/presentation/session_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  final config = Environment.instance.config;

  // ── Base local ────────────────────────────────────────────────────────────
  final local = await LocalDatabase.open(
    factory: databaseFactory,
    path: p.join(await getDatabasesPath(), 'workflow.db'),
  );
  final records = RecordStore(local);
  final outbox = OutboxStore(local, records);
  sl
    ..registerSingleton<LocalDatabase>(local)
    ..registerSingleton<RecordStore>(records)
    ..registerSingleton<OutboxStore>(outbox);

  // ── Red ───────────────────────────────────────────────────────────────────
  final connectivity = ConnectivityService();
  await connectivity.start(
    simulatedOffline: await records.getValue(KvKeys.simulateOffline) == '1',
  );
  sl.registerSingleton<ConnectivityService>(connectivity);

  final baseOptions = BaseOptions(
    baseUrl: '${config.apiBaseUrl}${ApiPaths.prefix}',
    connectTimeout: Duration(milliseconds: config.apiTimeout),
    receiveTimeout: Duration(milliseconds: config.apiTimeout),
    headers: {'Content-Type': 'application/json'},
  );
  final guard = OfflineGuardInterceptor(connectivity);

  // Login y refresh: sin Bearer.
  final authDio = Dio(baseOptions)..interceptors.add(guard);
  final session = SessionManager(
    authDio: authDio,
    tokens: SecureTokenStore(const FlutterSecureStorage()),
  );

  final apiDio = Dio(baseOptions);
  apiDio.interceptors
    ..add(guard)
    ..add(AuthInterceptor(session, apiDio));

  // R2: URL firmada, sin auth ni baseUrl.
  final r2Dio = Dio()..interceptors.add(guard);

  final api = ApiClient(apiDio, r2Dio);
  sl
    ..registerSingleton<SessionManager>(session)
    ..registerSingleton<ApiClient>(api);

  // ── Sync y cola ───────────────────────────────────────────────────────────
  final profiles = ProfileRepository(records, api);
  final photos = PhotoService();
  final repo = FieldRepository(records);
  final engine = SyncEngine(
    fetcher: api,
    applier: SyncApplier(records, outbox),
    store: records,
  );
  final processor = OutboxProcessor(store: outbox, transport: api, session: session);
  final coordinator = SyncCoordinator(
    connectivity: connectivity,
    outbox: outbox,
    processor: processor,
    engine: engine,
    store: records,
    profiles: profiles,
    afterPull: () => _prefetchCurrentPhotos(repo, profiles, records, photos, api),
  );
  sl
    ..registerSingleton<ProfileRepository>(profiles)
    ..registerSingleton<PhotoService>(photos)
    ..registerSingleton<FieldRepository>(repo)
    ..registerSingleton<SyncEngine>(engine)
    ..registerSingleton<OutboxProcessor>(processor)
    ..registerSingleton<SyncCoordinator>(coordinator)
    ..registerSingleton<FieldActions>(
      FieldActions(outbox: outbox, onEnqueued: coordinator.kick),
    )
    ..registerSingleton<SessionCubit>(
      SessionCubit(
        session: session,
        profiles: profiles,
        local: local,
        records: records,
        outbox: outbox,
        coordinator: coordinator,
        repo: repo,
      ),
    );
}

/// Descarga previa (v4 §11): las fotos vigentes de los ítems del proyecto
/// actual, para verlas sin señal.
Future<void> _prefetchCurrentPhotos(
  FieldRepository repo,
  ProfileRepository profiles,
  RecordStore records,
  PhotoService photos,
  ApiClient api,
) async {
  final projectId = await records.getValue(KvKeys.selectedProjectId) ??
      profiles.current?.currentProjectId;
  if (projectId == null) return;
  final assets = await repo.projectAssets(projectId);
  final mine = profiles.current?.employeeId == null
      ? const []
      : await repo.myAssets(profiles.current!.employeeId!);
  await photos.prefetch(api, {
    for (final a in [...assets, ...mine])
      if (a.currentPhotoId != null) a.currentPhotoId!,
  });
}
