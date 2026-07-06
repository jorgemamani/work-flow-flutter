import 'package:equatable/equatable.dart';

/// Scope de acceso: limita los datos que un usuario puede ver/modificar.
/// Un empleado típico tiene scope de obra; admin/rrhh tienen scope global.
class PermissionScope extends Equatable {
  const PermissionScope({required this.tipo, this.obraId});

  /// 'global' | 'obra' | 'departamento'
  final String tipo;

  /// ID de la obra cuando tipo == 'obra'.
  final String? obraId;

  bool get isGlobal => tipo == 'global';

  factory PermissionScope.global() => const PermissionScope(tipo: 'global');
  factory PermissionScope.obra(String obraId) =>
      PermissionScope(tipo: 'obra', obraId: obraId);

  factory PermissionScope.fromJson(Map<String, dynamic> json) => PermissionScope(
        tipo: json['tipo'] as String? ?? 'global',
        obraId: json['obra_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        if (obraId != null) 'obra_id': obraId,
      };

  @override
  List<Object?> get props => [tipo, obraId];
}

/// Permisos granulares del usuario. La lógica evalúa `permisos` (strings tipo
/// `modulo.accion`) y NO el campo `rol` como string — esto permite que en el
/// futuro el admin defina roles custom sin tocar la app.
///
/// TODO(workflow): Reemplazar [UserPermissions.mock] por la respuesta real de
/// `GET /me`. Buscar: PERMISSIONS-MOCK.
class UserPermissions extends Equatable {
  const UserPermissions({
    required this.permisos,
    required this.scope,
    this.enObra = false,
    this.enDescanso = false,
  });

  /// Lista de strings con formato `modulo.accion` o `modulo.*`.
  /// Ejemplos: `obras.read`, `herramientas.write`, `logistica.*`.
  final List<String> permisos;

  final PermissionScope scope;

  /// Estado laboral del empleado — reutilizable en todas las pantallas.
  final bool enObra;
  final bool enDescanso;

  // ── Evaluadores genéricos ──────────────────────────────────────────────────

  bool has(String permission) => permisos.contains(permission);

  bool canRead(String module) =>
      permisos.contains('$module.read') ||
      permisos.contains('$module.*') ||
      permisos.contains('*');

  bool canWrite(String module) =>
      permisos.contains('$module.write') ||
      permisos.contains('$module.*') ||
      permisos.contains('*');

  bool canDelete(String module) =>
      permisos.contains('$module.delete') ||
      permisos.contains('$module.*') ||
      permisos.contains('*');

  // ── Shortcuts por módulo ───────────────────────────────────────────────────

  bool get canAccessInventory =>
      canRead('herramientas') || canRead('logistica');

  bool get canWriteInventory =>
      canWrite('herramientas') || canWrite('logistica');

  bool get canAccessObras => canRead('obras');
  bool get canWriteObras => canWrite('obras');

  bool get canAccessEmpleados => canRead('empleados');
  bool get canWriteEmpleados => canWrite('empleados');

  bool get canAccessBitacora => canRead('bitacora');
  bool get canWriteBitacora => canWrite('bitacora');

  bool get canAccessVehiculos => canRead('vehiculos');

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  /// ¿Debe mostrar el ítem "Inventario" en la bottom nav?
  bool get showInventoryTab => canAccessInventory;

  /// Bitácora para roles de campo: requiere estar activo en obra asignada.
  /// [tieneObras] indica si el usuario tiene al menos una obra asignada.
  bool showBitacoraTab({required bool isFieldRole, required bool tieneObras}) {
    if (!canAccessBitacora) return false;
    if (!isFieldRole) return true; // admin/rrhh/logística: solo el permiso alcanza
    return enObra && !enDescanso && tieneObras;
  }

  // ── Serialización ─────────────────────────────────────────────────────────

  factory UserPermissions.fromJson(Map<String, dynamic> json) => UserPermissions(
        permisos: List<String>.from(json['permisos'] as List? ?? []),
        scope: json['scope'] != null
            ? PermissionScope.fromJson(json['scope'] as Map<String, dynamic>)
            : PermissionScope.global(),
        enObra: json['en_obra'] as bool? ?? false,
        enDescanso: json['en_descanso'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'permisos': permisos,
        'scope': scope.toJson(),
        'en_obra': enObra,
        'en_descanso': enDescanso,
      };

  UserPermissions copyWith({
    List<String>? permisos,
    PermissionScope? scope,
    bool? enObra,
    bool? enDescanso,
  }) =>
      UserPermissions(
        permisos: permisos ?? this.permisos,
        scope: scope ?? this.scope,
        enObra: enObra ?? this.enObra,
        enDescanso: enDescanso ?? this.enDescanso,
      );

  @override
  List<Object?> get props => [permisos, scope, enObra, enDescanso];
}
