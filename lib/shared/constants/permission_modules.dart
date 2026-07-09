/// Catálogo canónico de módulos de permisos (`modulo.accion`).
///
/// Fuente de verdad compartida con el backend (`arqytop-api`).
/// Usar estas constantes en evaluadores y mocks — nunca strings sueltos.
abstract final class PermissionModules {
  // ── Módulos del backend ───────────────────────────────────────────────────
  static const users = 'users';
  static const roles = 'roles';
  static const projects = 'projects';
  static const employees = 'employees';
  static const inventory = 'inventory';
  static const warehouses = 'warehouses';
  static const transfers = 'transfers';
  static const audits = 'audits';
  static const reports = 'reports';
  static const incidents = 'incidents';
  static const tenants = 'tenants';

  /// Feature 100% mobile — el backend no lo expone todavía.
  static const bitacora = 'bitacora';
}
