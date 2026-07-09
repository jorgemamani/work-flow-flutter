/// Roles de la aplicación mobile.
///
/// ## Mapeo backend → app
///
/// | Backend (DB)        | AppUserRole          | Notas                              |
/// |---------------------|----------------------|------------------------------------|
/// | `SUPER_ADMIN`       | admin                | wildcard `*`                       |
/// | `ADMIN`             | admin                | seed demo: admin@minerademo.com    |
/// | `ANALYST`           | rrhh                 | acceso a reportes y empleados      |
/// | `STOCK_MANAGER`     | logistica            | gestiona inventario                |
/// | `WAREHOUSE_KEEPER`  | logistica            | gestiona almacenes                 |
///
/// Los roles de campo (`empleado`, `supervisor`, `fotografo`) aún no existen
/// como filas en el backend — se seedearán cuando haga falta.
enum AppUserRole {
  empleado,
  empleadoSupervisor,
  fotografo,
  rrhh,
  logistica,
  admin;

  // ── Slugs que pueden venir del backend (siempre en minúsculas tras normalizar) ─

  static const Set<String> _empleadoSlugs = {
    'empleado',
    'employee',
  };

  static const Set<String> _supervisorSlugs = {
    'empleado_supervisor',
    'empleadosupervisor',
    'supervisor',
    'employee_supervisor',
  };

  static const Set<String> _fotografoSlugs = {
    'fotografo',
    'photographer',
    'photo',
  };

  /// `analyst` → RRHH/analista de oficina.
  static const Set<String> _rrhhSlugs = {
    'rrhh',
    'hr',
    'recursos_humanos',
    'analyst',
  };

  /// `stock_manager` y `warehouse_keeper` → gestión de inventario.
  static const Set<String> _logisticaSlugs = {
    'logistica',
    'logistics',
    'stock_manager',
    'warehouse_keeper',
    'bodega',
  };

  /// `super_admin` y `admin` → acceso total.
  static const Set<String> _adminSlugs = {
    'admin',
    'administrator',
    'administrador',
    'super_admin',
  };

  // ── Getters ────────────────────────────────────────────────────────────────

  String get displayLabel => switch (this) {
        AppUserRole.empleado => 'Empleado',
        AppUserRole.empleadoSupervisor => 'Supervisor',
        AppUserRole.fotografo => 'Fotógrafo',
        AppUserRole.rrhh => 'RRHH',
        AppUserRole.logistica => 'Logística',
        AppUserRole.admin => 'Admin',
      };

  /// Slug que se persiste localmente. No necesariamente coincide con el slug
  /// exacto del backend — es solo la clave interna de la app.
  String get apiValue => switch (this) {
        AppUserRole.empleado => 'empleado',
        AppUserRole.empleadoSupervisor => 'empleado_supervisor',
        AppUserRole.fotografo => 'fotografo',
        AppUserRole.rrhh => 'rrhh',
        AppUserRole.logistica => 'logistica',
        AppUserRole.admin => 'admin',
      };

  /// Roles de campo: operan en obra y tienen restricciones adicionales en la UI
  /// (visibilidad de bitácora, estado enObra/enDescanso).
  bool get isFieldRole => switch (this) {
        AppUserRole.empleado ||
        AppUserRole.empleadoSupervisor ||
        AppUserRole.fotografo =>
          true,
        _ => false,
      };

  /// Convierte el rol recibido del backend (cualquier casing) al enum local.
  /// Fallback: [AppUserRole.empleado] — el rol con menos privilegios.
  static AppUserRole fromApi(dynamic value) {
    final raw =
        value?.toString().trim().toLowerCase().replaceAll(' ', '_') ?? '';
    if (_adminSlugs.contains(raw)) return AppUserRole.admin;
    if (_logisticaSlugs.contains(raw)) return AppUserRole.logistica;
    if (_rrhhSlugs.contains(raw)) return AppUserRole.rrhh;
    if (_supervisorSlugs.contains(raw)) return AppUserRole.empleadoSupervisor;
    if (_fotografoSlugs.contains(raw)) return AppUserRole.fotografo;
    if (_empleadoSlugs.contains(raw)) return AppUserRole.empleado;
    return AppUserRole.empleado;
  }
}
