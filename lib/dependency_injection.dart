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
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource_mock.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/forgot_password_usecase.dart';
import 'features/auth/domain/usecases/get_logged_user_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies() async {
  // --- External ---
  final sharedPrefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPrefs);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  // --- Core ---
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.instance.config.apiBaseUrl,
      connectTimeout: Duration(milliseconds: Environment.instance.config.apiTimeout),
      receiveTimeout: Duration(milliseconds: Environment.instance.config.apiTimeout),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  sl.registerSingleton<Dio>(dio);
  sl.registerSingleton<IHttpClient>(ApiHttpClient(sl<Dio>()));

  sl.registerSingleton<ILocalStorage>(
    LocalStorageImpl(sl<SharedPreferences>(), sl<FlutterSecureStorage>()),
  );

  // --- Auth feature ---
  // TODO(workflow): Quitar rama mock cuando el API esté listo. Buscar: AUTH-MOCK.
  sl.registerSingleton<IAuthRemoteDataSource>(
    MockAuthConfig.isEnabled
        ? AuthRemoteMockDataSource()
        : AuthRemoteDataSourceImpl(sl<IHttpClient>()),
  );

  sl.registerSingleton<IAuthRepository>(
    AuthRepositoryImpl(sl<IAuthRemoteDataSource>(), sl<ILocalStorage>()),
  );

  sl.registerSingleton<LoginUseCase>(LoginUseCase(sl<IAuthRepository>()));
  sl.registerSingleton<ForgotPasswordUseCase>(ForgotPasswordUseCase(sl<IAuthRepository>()));
  sl.registerSingleton<GetLoggedUserUseCase>(GetLoggedUserUseCase(sl<IAuthRepository>()));

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      forgotPasswordUseCase: sl<ForgotPasswordUseCase>(),
      getLoggedUserUseCase: sl<GetLoggedUserUseCase>(),
      authRepository: sl<IAuthRepository>(),
    ),
  );
}
