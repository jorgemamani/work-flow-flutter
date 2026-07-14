import 'package:dio/dio.dart';

import '../local_storage/domain/local_storage.dart';
import 'session_expired_handler.dart';

/// Interceptor de Dio que inyecta `Authorization: Bearer <token>` en cada
/// petición a la API. Ante un 401 limpia la sesión y notifica a la app.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._localStorage);

  final ILocalStorage _localStorage;

  static const _publicPaths = [
    '/api/v1/auth/login',
    '/api/v1/tenants/resolve',
    '/api/v1/auth/forgot-password',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      final isPublic = _publicPaths.any(path.contains);
      if (!isPublic) {
        await _localStorage.clearSession();
        await SessionExpiredHandler.instance.notify();
      }
    }
    handler.next(err);
  }
}
