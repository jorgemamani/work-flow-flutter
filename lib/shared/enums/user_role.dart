enum UserRole {
  role1,
  role2,
  role3;

  static UserRole fromInt(int value) {
    return switch (value) {
      1 => UserRole.role1,
      2 => UserRole.role2,
      3 => UserRole.role3,
      _ => UserRole.role1,
    };
  }

  int get value => switch (this) {
        UserRole.role1 => 1,
        UserRole.role2 => 2,
        UserRole.role3 => 3,
      };
}
