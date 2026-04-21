import '../../domain/entities/user.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/user_type.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.type,
    required super.role,
    super.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      type: UserType.fromString(json['type'] as String? ?? 'employee'),
      role: UserRole.fromInt(json['role'] as int? ?? 1),
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'type': type.name,
        'role': role.value,
        'avatar_url': avatarUrl,
      };
}
