import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/environment/environment.dart';
import 'config/mock_auth_config.dart';
import 'core/http_client/data/api_http_client_impl.dart';
import 'core/http_client/domain/http_client.dart';
import 'core/local_storage/data/local_storage_impl.dart';
import 'core/local_storage/domain/local_storage.dart';
import 'core/network/auth_interceptor.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource_mock.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/get_logged_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/inventory/data/datasources/asset_remote_datasource.dart';
import 'features/inventory/data/repositories/asset_catalog_repository_impl.dart';
import 'features/inventory/data/repositories/asset_repository_impl.dart';
import 'features/inventory/domain/repositories/asset_catalog_repository.dart';
import 'features/inventory/domain/repositories/asset_repository.dart';
import 'features/inventory/domain/usecases/create_asset_usecase.dart';
import 'features/inventory/domain/usecases/create_brand_usecase.dart';
import 'features/inventory/domain/usecases/create_model_usecase.dart';
import 'features/inventory/domain/usecases/delete_asset_usecase.dart';
import 'features/inventory/domain/usecases/get_assets_usecase.dart';
import 'features/inventory/domain/usecases/get_brands_usecase.dart';
import 'features/inventory/domain/usecases/get_models_usecase.dart';
import 'features/inventory/domain/usecases/update_asset_usecase.dart';
import 'features/inventory/domain/usecases/upload_asset_image_usecase.dart';
import 'features/inventory/presentation/bloc/asset_form_bloc.dart';
import 'features/inventory/presentation/bloc/inventory_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // ── External ──────────────────────────────────────────────────────────────
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // ── Core: Storage ─────────────────────────────────────────────────────────
  sl.registerSingleton<ILocalStorage>(
    LocalStorageImpl(sl<SharedPreferences>(), sl<FlutterSecureStorage>()),
  );

  // ── Core: Dio principal (con interceptor de auth) ─────────────────────────
  final apiDio = Dio(
    BaseOptions(
      baseUrl: Environment.instance.config.apiBaseUrl,
      connectTimeout:
          Duration(milliseconds: Environment.instance.config.apiTimeout),
      receiveTimeout:
          Duration(milliseconds: Environment.instance.config.apiTimeout),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  apiDio.interceptors.add(AuthInterceptor(sl<ILocalStorage>()));

  sl.registerSingleton<Dio>(apiDio);
  sl.registerSingleton<IHttpClient>(ApiHttpClient(sl<Dio>()));

  // ── Core: Dio para R2 (sin interceptores de auth — URL ya firmada) ─────────
  final r2Dio = Dio();
  sl.registerSingleton<Dio>(r2Dio, instanceName: 'r2');

  // ── Auth feature ──────────────────────────────────────────────────────────
  sl.registerSingleton<IAuthRemoteDataSource>(
    MockAuthConfig.isEnabled
        ? AuthRemoteMockDataSource()
        : AuthRemoteDataSourceImpl(sl<IHttpClient>()),
  );

  sl.registerSingleton<IAuthRepository>(
    AuthRepositoryImpl(sl<IAuthRemoteDataSource>(), sl<ILocalStorage>()),
  );

  sl.registerSingleton<LoginUseCase>(LoginUseCase(sl<IAuthRepository>()));
  sl.registerSingleton<ForgotPasswordUseCase>(
      ForgotPasswordUseCase(sl<IAuthRepository>()));
  sl.registerSingleton<GetLoggedUserUseCase>(
      GetLoggedUserUseCase(sl<IAuthRepository>()));

  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      getLoggedUserUseCase: sl<GetLoggedUserUseCase>(),
      authRepository: sl<IAuthRepository>(),
    ),
  );

  // ── Inventory feature ─────────────────────────────────────────────────────
  sl.registerSingleton<IAssetRemoteDataSource>(
    AssetRemoteDataSourceImpl(
      sl<IHttpClient>(),
      sl<Dio>(instanceName: 'r2'),
    ),
  );

  sl.registerSingleton<IAssetRepository>(
    AssetRepositoryImpl(sl<IAssetRemoteDataSource>()),
  );

  sl.registerSingleton<IAssetCatalogRepository>(
    AssetCatalogRepositoryImpl(sl<IAssetRemoteDataSource>()),
  );

  // Use cases
  sl.registerSingleton<GetAssetsUseCase>(
      GetAssetsUseCase(sl<IAssetRepository>()));
  sl.registerSingleton<CreateAssetUseCase>(
      CreateAssetUseCase(sl<IAssetRepository>()));
  sl.registerSingleton<UpdateAssetUseCase>(
      UpdateAssetUseCase(sl<IAssetRepository>()));
  sl.registerSingleton<DeleteAssetUseCase>(
      DeleteAssetUseCase(sl<IAssetRepository>()));
  sl.registerSingleton<UploadAssetImageUseCase>(
      UploadAssetImageUseCase(sl<IAssetRepository>()));

  sl.registerSingleton<GetBrandsUseCase>(
      GetBrandsUseCase(sl<IAssetCatalogRepository>()));
  sl.registerSingleton<CreateBrandUseCase>(
      CreateBrandUseCase(sl<IAssetCatalogRepository>()));
  sl.registerSingleton<GetModelsUseCase>(
      GetModelsUseCase(sl<IAssetCatalogRepository>()));
  sl.registerSingleton<CreateModelUseCase>(
      CreateModelUseCase(sl<IAssetCatalogRepository>()));

  // Blocs
  sl.registerFactory<InventoryBloc>(
    () => InventoryBloc(
      getAssetsUseCase: sl<GetAssetsUseCase>(),
      deleteAssetUseCase: sl<DeleteAssetUseCase>(),
    ),
  );

  sl.registerFactory<AssetFormBloc>(
    () => AssetFormBloc(
      getBrandsUseCase: sl<GetBrandsUseCase>(),
      createBrandUseCase: sl<CreateBrandUseCase>(),
      getModelsUseCase: sl<GetModelsUseCase>(),
      createModelUseCase: sl<CreateModelUseCase>(),
      createAssetUseCase: sl<CreateAssetUseCase>(),
      updateAssetUseCase: sl<UpdateAssetUseCase>(),
      uploadAssetImageUseCase: sl<UploadAssetImageUseCase>(),
    ),
  );
}
