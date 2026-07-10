import 'package:equatable/equatable.dart';

import '../../../../shared/constants/permission_modules.dart';

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

  /// Soporta camelCase del API (`obraId`) y snake_case del storage local.
  factory PermissionScope.fromJson(Map<String, dynamic> json) => PermissionScope(
        tipo: json['tipo'] as String? ?? 'global',
        obraId: json['obraId'] as String? ?? json['obra_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        if (obraId != null) 'obra_id': obraId,
      };

  @override
  List<Object?> get props => [tipo, obraId];
}

/// Permisos granulares del usuario. La lógica evalúa `permisos` (strings tipo
/// `modulo.accion`) y NO el campo `rol` como string.
class UserPermissions extends Equatable {
  const UserPermissions({
    required this.permisos,
    required this.scope,
    this.enObra = false,
    this.enDescanso = false,
  });

  /// Lista de strings con formato `modulo.accion` o `modulo.*`.
  /// Ejemplos: `projects.read`, `inventory.write`, `inventory.*`.
  final List<String> permisos;

  final PermissionScope scope;

  /// Estado laboral del empleado — reutilizable en todas las pantallas.
  final bool enObra;
  final bool enDescanso;

  // ── Evaluadores genéricos ──────────────────────────────────────────────────

  bool has(String permission) =>
      permisos.contains(permission) || permisos.contains('*');

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

  // ── Shortcuts por módulo (catálogo API) ───────────────────────────────────

  bool get canAccessInventory =>
      canRead(PermissionModules.inventory) ||
      canRead(PermissionModules.warehouses) ||
      canRead(PermissionModules.transfers);

  bool get canWriteInventory =>
      canWrite(PermissionModules.inventory) ||
      canWrite(PermissionModules.warehouses) ||
      canWrite(PermissionModules.transfers);

  bool get canAccessObras => canRead(PermissionModules.projects);
  bool get canWriteObras => canWrite(PermissionModules.projects);

  bool get canAccessEmpleados => canRead(PermissionModules.employees);
  bool get canWriteEmpleados => canWrite(PermissionModules.employees);

  /// Bitácora es feature mobile; también acepta `audits` del backend.
  bool get canAccessBitacora =>
      canRead(PermissionModules.bitacora) || canRead(PermissionModules.audits);

  bool get canWriteBitacora =>
      canWrite(PermissionModules.bitacora) || canWrite(PermissionModules.audits);

  /// Vehículos no tienen módulo propio — se cubren con `inventory`.
  bool get canAccessVehiculos => canRead(PermissionModules.inventory);

  bool get canAccessReports => canRead(PermissionModules.reports);

  // ── Helpers de UI ─────────────────────────────────────────────────────────

  bool get showInventoryTab => canAccessInventory;

  /// Bitácora para roles de campo: requiere estar activo en obra asignada.
  bool showBitacoraTab({required bool isFieldRole, required bool tieneObras}) {
    if (!canAccessBitacora) return false;
    if (!isFieldRole) return true;
    return enObra && !enDescanso && tieneObras;
  }

  // ── Serialización ─────────────────────────────────────────────────────────

  /// Parsea `GET /auth/me` (camelCase) o el storage local (snake_case).
  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    final estado = _readEstado(json);
    return UserPermissions(
      permisos: List<String>.from(json['permisos'] as List? ?? []),
      scope: json['scope'] != null
          ? PermissionScope.fromJson(json['scope'] as Map<String, dynamic>)
          : PermissionScope.global(),
      enObra: estado.$1,
      enDescanso: estado.$2,
    );
  }

  /// Parsea directamente el bloque `data` de `GET /auth/me`.
  factory UserPermissions.fromMeResponse(Map<String, dynamic> data) {
    return UserPermissions.fromJson({
      'permisos': data['permisos'],
      'scope': data['scope'],
      'estadoActual': data['estadoActual'],
    });
  }

  static (bool enObra, bool enDescanso) _readEstado(Map<String, dynamic> json) {
    final estado = json['estadoActual'] ?? json['estado_actual'];
    if (estado is! Map<String, dynamic>) return (false, false);
    return (
      estado['enObra'] as bool? ?? estado['en_obra'] as bool? ?? false,
      estado['enDescanso'] as bool? ??
          estado['en_descanso'] as bool? ??
          false,
    );
  }

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
