/// Utilidades centralizadas para parsear respuestas de la API.
///
/// Todas las respuestas del backend vienen envueltas en `{ "data": ... }`.
abstract final class ApiResponseParser {
  /// Desenvuelve el campo `data` de una respuesta JSON de la API.
  static Map<String, dynamic> unwrap(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Respuesta API inválida: se esperaba "data" como objeto.',
      );
    }
    return data;
  }

  /// Desenvuelve `data` cuando es una lista.
  static List<dynamic> unwrapList(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! List<dynamic>) {
      throw const FormatException(
        'Respuesta API inválida: se esperaba "data" como lista.',
      );
    }
    return data;
  }
}
