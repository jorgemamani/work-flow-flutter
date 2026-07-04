import '../../../../config/mock_auth_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/entities/employee_obra_entities.dart';
import '../../../../shared/enums/app_user_role.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Login local sin red. Ver [MockAuthConfig] y TODO `AUTH-MOCK`.
class AuthRemoteMockDataSource implements IAuthRemoteDataSource {
  @override
  Future<({UserModel user, String token, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final ok = email.trim().toLowerCase() == MockAuthConfig.email.toLowerCase() &&
        password == MockAuthConfig.password;

    if (!ok) {
      throw const AppException(
        message: 'Credenciales incorrectas (modo mock local).',
      );
    }

    final user = UserModel(
      id: 'mock-local-user',
      name: 'Juan Pérez',
      email: MockAuthConfig.email,
      role: AppUserRole.empleado,
      obras: _mockObrasJuanPerez(),
    );

    return (
      user: user,
      token: 'mock_access_token',
      refreshToken: 'mock_refresh_token',
    );
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

/// Dos obras activas para probar el selector (misma persona en varias obras).
List<ObraAssignment> _mockObrasJuanPerez() {
  return const [
    ObraAssignment(
      id: 'obra-mina-san-jose',
      nombre: 'Mina San José',
      ubicacion: 'Sector Norte - Nivel 3',
      supervisorNombre: 'Carlos Mendoza',
      companeros: [
        ObraColleague(id: 'c1', nombre: 'Juan Pérez', puesto: 'Operador'),
        ObraColleague(id: 'c2', nombre: 'María González', puesto: 'Técnico'),
        ObraColleague(id: 'c3', nombre: 'Pedro Sánchez', puesto: 'Operador'),
        ObraColleague(id: 'c4', nombre: 'Ana Torres', puesto: 'Técnico de Seguridad'),
      ],
      productos: [
        ObraProduct(
          id: 'p1',
          nombre: 'Taladro Neumático',
          cantidad: 3,
          status: ObraProductStatus.operativo,
        ),
        ObraProduct(
          id: 'p2',
          nombre: 'Casco de Seguridad',
          cantidad: 15,
          status: ObraProductStatus.operativo,
        ),
        ObraProduct(
          id: 'p3',
          nombre: 'Explosivos C4',
          cantidad: 50,
          status: ObraProductStatus.enUso,
        ),
        ObraProduct(
          id: 'p4',
          nombre: 'Carretilla Minera',
          cantidad: 8,
          status: ObraProductStatus.operativo,
        ),
        ObraProduct(
          id: 'p5',
          nombre: 'Lámpara Frontal',
          cantidad: 12,
          status: ObraProductStatus.operativo,
        ),
      ],
    ),
    ObraAssignment(
      id: 'obra-refineria',
      nombre: 'Refinería Central',
      ubicacion: 'Planta B - Módulo 2',
      supervisorNombre: 'Laura Rivas',
      companeros: [
        ObraColleague(id: 'c10', nombre: 'Juan Pérez', puesto: 'Operador'),
        ObraColleague(id: 'c11', nombre: 'Diego Fuentes', puesto: 'Supervisor de turno'),
        ObraColleague(id: 'c12', nombre: 'Elena Vargas', puesto: 'Técnico'),
      ],
      productos: [
        ObraProduct(
          id: 'p20',
          nombre: 'Detector de gas',
          cantidad: 6,
          status: ObraProductStatus.operativo,
        ),
        ObraProduct(
          id: 'p21',
          nombre: 'Kit de primeros auxilios',
          cantidad: 4,
          status: ObraProductStatus.mantenimiento,
        ),
      ],
    ),
  ];
}
