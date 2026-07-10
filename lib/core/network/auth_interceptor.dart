import 'package:dio/dio.dart';

import '../local_storage/domain/local_storage.dart';

/// Interceptor de Dio que inyecta `Authorization: Bearer <token>` en cada
/// petición a la API. Si no hay token (usuario no autenticado) la petición
/// sale sin el header — los endpoints públicos no lo requieren.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._localStorage);

  final ILocalStorage _localStorage;

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
}
