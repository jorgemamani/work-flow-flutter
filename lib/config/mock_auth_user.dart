import '../shared/enums/app_user_role.dart';

/// Alcance de obras que recibe el usuario mock al iniciar sesión.
enum MockObrasScope {
  /// Obras asignadas al usuario (empleado, supervisor, fotógrafo).
  assigned,

  /// Todas las obras del sistema (admin, RRHH, logística).
  global,

  /// Sin obras — útil para probar el placeholder "no estás asignado".
  none,
}

/// Usuario de prueba para login mock. Cada entrada del catálogo representa
/// lo que en producción vendría de `POST /auth/login` + `GET /me`.
class MockAuthUser {
  const MockAuthUser({
    required this.email,
    required this.password,
    required this.id,
    required this.name,
    required this.role,
    this.obrasScope = MockObrasScope.assigned,
    this.enObra = true,
    this.enDescanso = false,
  });

  final String email;
  final String password;
  final String id;
  final String name;
  final AppUserRole role;
  final MockObrasScope obrasScope;
  final bool enObra;
  final bool enDescanso;

  String get roleLabel => role.displayLabel;

  /// Etiqueta para chips de acceso rápido en login (debug).
  String get devLabel => switch (obrasScope) {
        MockObrasScope.none => '$roleLabel (sin obra)',
        _ => roleLabel,
      };
}
