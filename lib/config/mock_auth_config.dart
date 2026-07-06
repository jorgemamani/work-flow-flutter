import 'package:flutter/foundation.dart' show kDebugMode;

/// Interruptor del login mock. Las credenciales y perfiles viven en
/// [MockAuthUsers] — este archivo solo controla si el mock está activo.
///
/// TODO(workflow): Eliminar cuando el login real esté integrado. Buscar: AUTH-MOCK.
class MockAuthConfig {
  MockAuthConfig._();

  /// `false` fuerza API real incluso en debug.
  static const bool useMockAuth = true;

  /// Solo aplica en debug (release/profile nunca usa mock).
  static bool get isEnabled => kDebugMode && useMockAuth;
}
