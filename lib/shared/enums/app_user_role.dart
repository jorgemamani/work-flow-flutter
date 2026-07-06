/// Roles de la aplicación. Para sumar uno nuevo: agregar valor al enum,
/// [apiValues], [fromApi] y [displayLabel].
enum AppUserRole {
  empleado,
  empleadoSupervisor,
  fotografo,
  rrhh,
  logistica,
  admin;

  static const Set<String> _empleadoSlugs = {'empleado', 'employee'};
  static const Set<String> _supervisorSlugs = {
    'empleado_supervisor',
    'empleadosupervisor',
    'supervisor',
    'employee_supervisor',
  };
  static const Set<String> _fotografoSlugs = {'fotografo', 'photographer', 'photo'};
  static const Set<String> _rrhhSlugs = {'rrhh', 'hr', 'recursos_humanos', 'recursos humanos'};
  static const Set<String> _logisticaSlugs = {
    'logistica',
    'logistics',
    'inventario',
    'inventory',
    'bodega',
  };
  static const Set<String> _adminSlugs = {'admin', 'administrator', 'administrador'};

  String get displayLabel => switch (this) {
        AppUserRole.empleado => 'Empleado',
        AppUserRole.empleadoSupervisor => 'Supervisor',
        AppUserRole.fotografo => 'Fotógrafo',
        AppUserRole.rrhh => 'RRHH',
        AppUserRole.logistica => 'Logística',
        AppUserRole.admin => 'Admin',
      };

  String get apiValue => switch (this) {
        AppUserRole.empleado => 'empleado',
        AppUserRole.empleadoSupervisor => 'empleado_supervisor',
        AppUserRole.fotografo => 'fotografo',
        AppUserRole.rrhh => 'rrhh',
        AppUserRole.logistica => 'logistica',
        AppUserRole.admin => 'admin',
      };

  static AppUserRole fromApi(dynamic value) {
    final raw = value?.toString().trim().toLowerCase().replaceAll(' ', '_') ?? '';
    if (_empleadoSlugs.contains(raw)) return AppUserRole.empleado;
    if (_supervisorSlugs.contains(raw)) return AppUserRole.empleadoSupervisor;
    if (_fotografoSlugs.contains(raw)) return AppUserRole.fotografo;
    if (_rrhhSlugs.contains(raw)) return AppUserRole.rrhh;
    if (_logisticaSlugs.contains(raw)) return AppUserRole.logistica;
    if (_adminSlugs.contains(raw)) return AppUserRole.admin;
    if (value is int) {
      return switch (value) {
        1 => AppUserRole.empleado,
        2 => AppUserRole.empleadoSupervisor,
        3 => AppUserRole.fotografo,
        4 => AppUserRole.admin,
        _ => AppUserRole.empleado,
      };
    }
    return AppUserRole.empleado;
  }
}
