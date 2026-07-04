import 'package:equatable/equatable.dart';

import '../../../../shared/entities/employee_obra_entities.dart';
import '../../../../shared/enums/app_user_role.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.roleRaw,
    this.avatarUrl,
    this.obras = const [],
  });

  final String id;
  final String name;
  final String email;
  final AppUserRole role;
  /// Valor crudo del backend cuando agreguen roles nuevos antes de mapearlos.
  final String? roleRaw;
  final String? avatarUrl;
  /// Obras en las que participa el usuario (empleado puede tener varias a la vez).
  final List<ObraAssignment> obras;

  @override
  List<Object?> get props => [id, name, email, role, roleRaw, avatarUrl, obras];
}
