import 'environment/environment.dart';

/// Interruptor centralizado de mocks.
///
/// El flag ya no es una constante hardcodeada: lo controla [Environment].
/// En `dev` → mock activo. En `staging` y `prod` → siempre API real.
///
/// Para forzar la API real en desarrollo, setear `useMockData = false`
/// en [DevConfig] o correr con `--dart-define=ENVIRONMENT=staging`.
class MockAuthConfig {
  MockAuthConfig._();

  static bool get isEnabled => Environment.instance.useMockData;
}
