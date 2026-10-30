import 'package:dio/dio.dart';

import 'connectivity_service.dart';

/// Con el modo sin conexión activo (o sin red), corta la llamada antes de
/// salir: la app se comporta igual que en la mina.
class OfflineGuardInterceptor extends Interceptor {
  OfflineGuardInterceptor(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_connectivity.isOnline) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'offline',
        ),
      );
      return;
    }
    handler.next(options);
  }
}

/// ¿El error fue de red (sin respuesta)?
bool isNetworkError(DioException e) =>
    e.response == null &&
    e.type != DioExceptionType.cancel &&
    e.type != DioExceptionType.badCertificate;
