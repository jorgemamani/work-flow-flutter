import 'package:flutter/foundation.dart' show kDebugMode;

/// Credenciales y flag para entrar al dashboard sin backend.
///
/// TODO(workflow): Eliminar [MockAuthConfig] y [AuthRemoteMockDataSource] cuando
/// el login real esté integrado. Buscar en el repo: `AUTH-MOCK`.
class MockAuthConfig {
  MockAuthConfig._();

  /// Poné `false` para forzar API real incluso en debug.
  static const bool useMockAuth = true;

  /// Solo aplica en modo debug (release/profile nunca usa mock).
  static bool get isEnabled => kDebugMode && useMockAuth;

  static const String email = 'dev@local.test';
  static const String password = 'dev123456';
}
