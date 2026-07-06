import '../features/auth/domain/entities/user_permissions.dart';
import '../shared/enums/app_user_role.dart';

/// Permisos simulados por rol. En producción esto vendrá de `GET /me`
/// con la forma:
/// ```json
/// {
///   "usuario": { "id": 1, "nombre": "...", "rol": "empleado" },
///   "permisos": ["obras.read", "herramientas.read", ...],
///   "scope": { "tipo": "obra", "obra_id": "12" },
///   "estado_actual": { "en_obra": true, "en_descanso": false }
/// }
/// ```
///
/// TODO(workflow): Reemplazar [permissionsFor] con la respuesta real de la API.
/// Buscar: PERMISSIONS-MOCK.
class MockPermissionsConfig {
  MockPermissionsConfig._();

  /// Devuelve los permisos para el rol dado.
  /// Reemplazar esta función por la llamada real a la API.
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

  // ── Listas de permisos por rol ─────────────────────────────────────────────

  static const List<String> _adminPermisos = [
    'obras.*',
    'empleados.*',
    'herramientas.*',
    'logistica.*',
    'bitacora.*',
    'vehiculos.*',
    'reportes.*',
    'configuracion.*',
  ];

  static const List<String> _rrhhPermisos = [
    'obras.*',
    'empleados.*',
    'herramientas.read',
    'vehiculos.*',
    'bitacora.*',
    'reportes.read',
  ];

  static const List<String> _logisticaPermisos = [
    'herramientas.*',
    'logistica.*',
    'bitacora.read',
    'vehiculos.read',
    'obras.read',
  ];

  static const List<String> _supervisorPermisos = [
    'obras.read',
    'obras.write',
    'herramientas.read',
    'empleados.read',
    'bitacora.*',
    'vehiculos.read',
  ];

  static const List<String> _fotografoPermisos = [
    'obras.read',
    'bitacora.read',
    'bitacora.write',
  ];

  static const List<String> _empleadoPermisos = [
    'obras.read',
    'herramientas.read',
    'empleados.read',
    'bitacora.read',
    'bitacora.write',
  ];
}
