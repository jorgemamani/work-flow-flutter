abstract class BaseConfig {
  String get apiBaseUrl;
  int get apiTimeout;

  /// Cuando es `true` la app usa datasources mock (sin red).
  /// Solo activo en el entorno `mock`; en `staging` y `prod` siempre es `false`.
  bool get useMockData;
}
