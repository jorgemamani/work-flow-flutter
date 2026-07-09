import '../../domain/entities/user.dart';
import '../../domain/entities/user_permissions.dart';
import '../../../../shared/entities/employee_obra_entities.dart';
import '../../../../shared/enums/app_user_role.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.permissions,
    super.roleRaw,
    super.avatarUrl,
    super.obras,
  });

  /// Parsea `AuthUserDto` de `POST /auth/login` (sin scope ni estado).
  factory UserModel.fromAuthUserDto(Map<String, dynamic> json) {
    final firstName = json['firstName'] as String? ?? '';
    final lastName = json['lastName'] as String? ?? '';
    final fullName = [firstName, lastName]
        .where((s) => s.isNotEmpty)
        .join(' ')
        .trim();

    final rawPerms = json['permissions'];
    final permisos = rawPerms is List
        ? List<String>.from(rawPerms)
        : <String>[];

    return UserModel(
      id: json['id'] as String,
      name: fullName.isNotEmpty ? fullName : json['email'] as String,
      email: json['email'] as String,
      role: AppUserRole.fromApi(json['role']),
      roleRaw: json['role'] as String?,
      permissions: UserPermissions(
        permisos: permisos,
        scope: PermissionScope.global(),
      ),
      avatarUrl: json['avatarUrl'] as String?,
      obras: const [],
    );
  }

  /// Enriquece el usuario con `GET /auth/me` (permisos, scope, estado).
  UserModel applyMeResponse(Map<String, dynamic> meData) {
    final usuario = meData['usuario'] as Map<String, dynamic>;
    final permissions = UserPermissions.fromMeResponse(meData);

    return UserModel(
      id: usuario['id'] as String? ?? id,
      name: usuario['nombre'] as String? ?? name,
      email: email,
      role: AppUserRole.fromApi(usuario['rol'] ?? roleRaw ?? role.apiValue),
      roleRaw: usuario['rol'] as String? ?? roleRaw,
      permissions: permissions,
      avatarUrl: avatarUrl,
      obras: obras,
    );
  }

  /// Parsea el usuario persistido localmente (storage).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleSource =
        json['role'] ?? json['role_raw'] ?? json['user_role'] ?? json['type'];
    final role = AppUserRole.fromApi(roleSource);

    final UserPermissions permissions;
    if (json['permissions'] is Map<String, dynamic>) {
      permissions =
          UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>);
    } else {
      permissions = const UserPermissions(
        permisos: [],
        scope: PermissionScope(tipo: 'global'),
      );
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ??
          '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}'.trim(),
      email: json['email'] as String,
      role: role,
      permissions: permissions,
      roleRaw: json['role_raw'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      obras: _parseObras(json['obras']),
    );
  }

  static List<ObraAssignment> _parseObras(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    return raw
        .map((e) => ObraAssignment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.apiValue,
        if (roleRaw != null) 'role_raw': roleRaw,
        'avatar_url': avatarUrl,
        'obras': obras.map((e) => e.toJson()).toList(),
        'permissions': permissions.toJson(),
      };
}
