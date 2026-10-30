/// Error de la API con el `message` listo para mostrar (contrato §1).
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

/// La sesión no se puede renovar: hay que volver a ingresar.
class SessionExpiredException implements Exception {
  const SessionExpiredException();
}
