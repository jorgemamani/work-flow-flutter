import '../features/auth/domain/entities/user_permissions.dart';
import '../shared/constants/permission_modules.dart';
import '../shared/enums/app_user_role.dart';

/// Permisos simulados por rol usando el catálogo canónico del API
/// (`modulo.accion` en inglés). En producción vienen de `GET /auth/me`.
///
/// `bitacora.*` se mantiene solo en mock — es feature 100% mobile.
class MockPermissionsConfig {
  MockPermissionsConfig._();

  static UserPermissions permissionsFor(
    AppUserRole role, {
    String? obraId,
    bool? enObra,
    bool? enDescanso,
  }) {
    final (permisos, scope) = switch (role) {
      AppUserRole.admin => (
          _adminPermisos,
          PermissionScope.global(),
        ),
      AppUserRole.rrhh => (
          _rrhhPermisos,
          PermissionScope.global(),
        ),
      AppUserRole.logistica => (
          _logisticaPermisos,
          PermissionScope.global(),
        ),
      AppUserRole.empleadoSupervisor => (
          _supervisorPermisos,
          obraId != null
              ? PermissionScope.obra(obraId)
              : PermissionScope.global(),
        ),
      AppUserRole.fotografo => (
          _fotografoPermisos,
          obraId != null
              ? PermissionScope.obra(obraId)
              : PermissionScope.global(),
        ),
      AppUserRole.empleado => (
          _empleadoPermisos,
          obraId != null
              ? PermissionScope.obra(obraId)
              : PermissionScope.global(),
        ),
    };

    return UserPermissions(
      permisos: permisos,
      scope: scope,
      enObra: enObra ?? true,
      enDescanso: enDescanso ?? false,
    );
  }

  // ── Listas alineadas al catálogo API (sección 2 del doc de integración) ──

  /// Equivalente a rol `ADMIN` del backend + `bitacora.*` local.
  static const List<String> _adminPermisos = [
    '${PermissionModules.users}.*',
    '${PermissionModules.roles}.*',
    '${PermissionModules.projects}.*',
    '${PermissionModules.employees}.*',
    '${PermissionModules.inventory}.*',
    '${PermissionModules.warehouses}.*',
    '${PermissionModules.transfers}.*',
    '${PermissionModules.audits}.*',
    '${PermissionModules.reports}.*',
    '${PermissionModules.incidents}.*',
    '${PermissionModules.bitacora}.*',
  ];

  static const List<String> _rrhhPermisos = [
    '${PermissionModules.projects}.*',
    '${PermissionModules.employees}.*',
    '${PermissionModules.inventory}.read',
    '${PermissionModules.reports}.read',
    '${PermissionModules.bitacora}.*',
  ];

  static const List<String> _logisticaPermisos = [
    '${PermissionModules.inventory}.*',
    '${PermissionModules.warehouses}.*',
    '${PermissionModules.transfers}.*',
    '${PermissionModules.projects}.read',
    '${PermissionModules.bitacora}.read',
  ];

  static const List<String> _supervisorPermisos = [
    '${PermissionModules.projects}.read',
    '${PermissionModules.projects}.write',
    '${PermissionModules.inventory}.read',
    '${PermissionModules.employees}.read',
    '${PermissionModules.bitacora}.*',
  ];

  static const List<String> _fotografoPermisos = [
    '${PermissionModules.projects}.read',
    '${PermissionModules.audits}.read',
    '${PermissionModules.audits}.write',
    '${PermissionModules.bitacora}.read',
    '${PermissionModules.bitacora}.write',
  ];

  static const List<String> _empleadoPermisos = [
    '${PermissionModules.projects}.read',
    '${PermissionModules.inventory}.read',
    '${PermissionModules.employees}.read',
    '${PermissionModules.bitacora}.read',
    '${PermissionModules.bitacora}.write',
  ];
}
