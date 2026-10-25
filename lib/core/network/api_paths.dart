/// Paths de la API, relativos a `<host>/api/v1`. Nunca escribir un endpoint
/// suelto en un repositorio.
abstract final class ApiPaths {
  static const prefix = '/api/v1';

  // Auth
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';
  static const logout = '/auth/logout';
  static const me = '/auth/me';
  static const switchTenant = '/auth/switch-tenant';
  static const changePin = '/auth/me/pin';
  static const resolveTenant = '/tenants/resolve';

  // Sync
  static const syncChanges = '/sync/changes';

  // Hechos (PUT idempotente con id del cliente, contrato §4)
  static String asset(String id) => '/inventory/assets/$id';
  static String assetMovement(String id) => '/inventory/asset-movements/$id';
  static String assetStatusChange(String id) =>
      '/inventory/asset-status-changes/$id';
  static String remitoReception(String id) => '/remito-receptions/$id';
  static String verification(String id) => '/verifications/$id';
  static String submission(String id) => '/submissions/$id';
  static String incident(String id) => '/incidents/$id';
  static String requirement(String id) => '/requirements/$id';
  static String checkIn(String id) => '/check-ins/$id';
  static String attachment(String id) => '/attachments/$id';

  // Remito de devolución armado offline (POST idempotente con id del cliente)
  static const remitos = '/remitos';
  static String remitoSubmit(String id) => '/remitos/$id/submit';
}
