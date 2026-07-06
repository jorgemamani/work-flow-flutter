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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleSource = json['role'] ?? json['user_role'] ?? json['type'];
    final role = AppUserRole.fromApi(roleSource);

    // Permisos: vienen del campo `permisos` de la API (`GET /me`).
    // Si la respuesta no los incluye aún, se generan desde el rol (legacy).
    final UserPermissions permissions;
    if (json['permisos'] != null) {
      permissions = UserPermissions.fromJson({
        'permisos': json['permisos'],
        'scope': json['scope'],
        'en_obra': json['estado_actual']?['en_obra'],
        'en_descanso': json['estado_actual']?['en_descanso'],
      });
    } else if (json['permissions'] != null) {
      permissions = UserPermissions.fromJson(json['permissions'] as Map<String, dynamic>);
    } else {
      permissions = const UserPermissions(
        permisos: [],
        scope: PermissionScope(tipo: 'global'),
      );
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
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
