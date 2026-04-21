import 'package:equatable/equatable.dart';

import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/user_type.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.type,
    required this.role,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserType type;
  final UserRole role;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, name, email, type, role, avatarUrl];
}
