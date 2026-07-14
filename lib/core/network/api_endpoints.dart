/// Centraliza todos los paths de la API.
/// Nunca escribir un string de endpoint directamente en un datasource.
abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String resolveTenant = '/api/v1/tenants/resolve';
  static const String login = '/api/v1/auth/login';
  static const String forgotPassword = '/api/v1/auth/forgot-password';
  static const String me = '/api/v1/auth/me';

  // ── Inventory / Brands ────────────────────────────────────────────────────
  static const String brands = '/api/v1/inventory/brands';
  static String brandById(String id) => '/api/v1/inventory/brands/$id';

  // ── Inventory / Models ────────────────────────────────────────────────────
  static const String models = '/api/v1/inventory/models';
  static String modelById(String id) => '/api/v1/inventory/models/$id';

  // ── Inventory / Assets ────────────────────────────────────────────────────
  static const String assets = '/api/v1/inventory/assets';
  static String assetById(String id) => '/api/v1/inventory/assets/$id';

  // ── Projects ──────────────────────────────────────────────────────────────
  static const String projects = '/api/v1/projects';
  static String projectById(String id) => '/api/v1/projects/$id';

  // ── Warehouses ────────────────────────────────────────────────────────────
  static const String warehouses = '/api/v1/warehouses';
  static String warehouseById(String id) => '/api/v1/warehouses/$id';

  // ── Inventory / Conditions ────────────────────────────────────────────────
  static const String conditions = '/api/v1/inventory/conditions';
  static String conditionById(String id) => '/api/v1/inventory/conditions/$id';

  // ── Inventory / Asset Images ──────────────────────────────────────────────
  static String assetImagesPresign(String assetId) =>
      '/api/v1/inventory/assets/$assetId/images/presign';
  static String assetImagesConfirm(String assetId) =>
      '/api/v1/inventory/assets/$assetId/images';
  static String assetImages(String assetId) =>
      '/api/v1/inventory/assets/$assetId/images';
  static String assetImageById(String assetId, String imageId) =>
      '/api/v1/inventory/assets/$assetId/images/$imageId';
}
