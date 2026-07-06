import 'package:equatable/equatable.dart';

import '../../../../shared/entities/employee_obra_entities.dart';
import '../../../../shared/enums/app_user_role.dart';
import 'user_permissions.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.roleRaw,
    this.avatarUrl,
    this.obras = const [],
  });

  final String id;
  final String name;
  final String email;
  final AppUserRole role;

  /// Permisos granulares — evaluar siempre [permissions], nunca [role] en la UI.
  /// Vendrá de `GET /me` en producción. Ver: PERMISSIONS-MOCK.
  final UserPermissions permissions;

  /// Valor crudo del backend para roles no mapeados aún.
  final String? roleRaw;
  final String? avatarUrl;

  /// Obras en las que participa el usuario.
  final List<ObraAssignment> obras;

  @override
  List<Object?> get props =>
      [id, name, email, role, permissions, roleRaw, avatarUrl, obras];
}
