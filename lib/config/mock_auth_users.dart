import 'mock_auth_user.dart';
import '../shared/enums/app_user_role.dart';

/// Catálogo central de usuarios mock para desarrollo.
///
/// **Único archivo a editar** para cambiar credenciales de prueba.
/// En producción estos perfiles vienen de `POST /auth/login` + `GET /auth/me`.
///
/// Contraseña compartida: [defaultPassword]
class MockAuthUsers {
  MockAuthUsers._();

  static const String defaultPassword = 'dev123456';

  static const List<MockAuthUser> catalog = [
    MockAuthUser(
      email: 'empleado.sinobra@local.test',
      password: defaultPassword,
      id: 'mock-empleado-sin-obra',
      name: 'Pedro Sin Obra',
      role: AppUserRole.empleado,
      obrasScope: MockObrasScope.none,
      enObra: false,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'empleado@local.test',
      password: defaultPassword,
      id: 'mock-empleado',
      name: 'Juan Pérez',
      role: AppUserRole.empleado,
      obrasScope: MockObrasScope.assigned,
      enObra: true,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'supervisor@local.test',
      password: defaultPassword,
      id: 'mock-supervisor',
      name: 'Ana Supervisora',
      role: AppUserRole.empleadoSupervisor,
      obrasScope: MockObrasScope.assigned,
      enObra: true,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'fotografo@local.test',
      password: defaultPassword,
      id: 'mock-fotografo',
      name: 'Diego Fotógrafo',
      role: AppUserRole.fotografo,
      obrasScope: MockObrasScope.assigned,
      enObra: true,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'logistica@local.test',
      password: defaultPassword,
      id: 'mock-logistica',
      name: 'Marcos Logística',
      role: AppUserRole.logistica,
      obrasScope: MockObrasScope.global,
      enObra: false,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'rrhh@local.test',
      password: defaultPassword,
      id: 'mock-rrhh',
      name: 'Laura RRHH',
      role: AppUserRole.rrhh,
      obrasScope: MockObrasScope.global,
      enObra: false,
      enDescanso: false,
    ),
    MockAuthUser(
      email: 'admin@local.test',
      password: defaultPassword,
      id: 'mock-admin',
      name: 'Carlos Admin',
      role: AppUserRole.admin,
      obrasScope: MockObrasScope.global,
      enObra: false,
      enDescanso: false,
    ),
  ];

  static MockAuthUser? find({required String email, required String password}) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final user in catalog) {
      if (user.email.toLowerCase() == normalizedEmail &&
          user.password == password) {
        return user;
      }
    }
    return null;
  }

  /// Todos los usuarios del catálogo (sin duplicados).
  static List<MockAuthUser> get uniqueForDevUi => catalog;
}
