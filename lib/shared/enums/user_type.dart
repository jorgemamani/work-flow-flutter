enum UserType {
  employee,
  manager,
  admin;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => UserType.employee,
    );
  }
}
