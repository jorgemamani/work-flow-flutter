import 'package:dio/dio.dart';

import '../auth/session_manager.dart';
import '../outbox/outbox_processor.dart';

/// Pone `Authorization: Bearer …` y, ante un 401, refresca (rotando el
/// refresh token) y reintenta una vez.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session, this._dio);

  final SessionManager _session;
  final Dio _dio;

  static const _retried = 'auth.retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _session.ensureFresh();
    final token = await _session.accessToken();
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
    final opts = err.requestOptions;
    if (err.response?.statusCode != 401 || opts.extra[_retried] == true) {
      handler.next(err);
      return;
    }
    if (await _session.forceRefresh() != RefreshOutcome.ok) {
      handler.next(err);
      return;
    }
    try {
      opts.extra[_retried] = true;
      opts.headers['Authorization'] = 'Bearer ${await _session.accessToken()}';
      handler.resolve(await _dio.fetch<dynamic>(opts));
    } on DioException catch (e) {
      handler.next(e);
    }
  }
}
