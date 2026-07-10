import '../../../../config/mock_auth_user.dart';
import '../../../../config/mock_auth_users.dart';
import '../../../../config/mock_permissions_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/entities/employee_obra_entities.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Login local sin red. Resuelve credenciales contra [MockAuthUsers.catalog].
///
/// Para agregar o modificar usuarios de prueba, editá:
/// `lib/config/mock_auth_users.dart`
///
/// TODO(workflow): Reemplazar por API real. Buscar: AUTH-MOCK.
class AuthRemoteMockDataSource implements IAuthRemoteDataSource {
  @override
  Future<AuthLoginResult> login({
    required String cuit,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final mockUser = MockAuthUsers.find(email: email, password: password);
    if (mockUser == null) {
      throw const AppException(
        message: 'Credenciales incorrectas (modo mock local).',
      );
    }

    final obras = _obrasParaScope(mockUser.obrasScope);
    final obraId = obras.isNotEmpty ? obras.first.id : null;

    final permissions = MockPermissionsConfig.permissionsFor(
      mockUser.role,
      obraId: obraId,
      enObra: mockUser.enObra,
      enDescanso: mockUser.enDescanso,
    );

    final user = UserModel(
      id: mockUser.id,
      name: mockUser.name,
      email: mockUser.email,
      role: mockUser.role,
      permissions: permissions,
      obras: obras,
    );

    return (
      user: user,
      accessToken: 'mock_access_token_${mockUser.id}',
      refreshToken: 'mock_refresh_token_${mockUser.id}',
    );
  }

  @override
  Future<UserModel> getMe({required UserModel baseUser}) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return baseUser;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  static List<ObraAssignment> _obrasParaScope(MockObrasScope scope) =>
      switch (scope) {
        MockObrasScope.global => _todasLasObras(),
        MockObrasScope.assigned => _mockObrasJuanPerez(),
        MockObrasScope.none => const [],
      };
}

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

/// Todas las obras del sistema (admin / rrhh / logística).
List<ObraAssignment> _todasLasObras() {
  return [
    ..._mockObrasJuanPerez(),
    const ObraAssignment(
      id: 'obra-planta-norte',
      nombre: 'Planta Norte',
      ubicacion: 'Zona Industrial - Sector 5',
      supervisorNombre: 'Roberto Castillo',
      companeros: [
        ObraColleague(id: 'c20', nombre: 'Sofía Morales', puesto: 'Operador'),
        ObraColleague(id: 'c21', nombre: 'Tomás Ríos', puesto: 'Mecánico'),
        ObraColleague(id: 'c22', nombre: 'Valentina Cruz', puesto: 'Técnico'),
        ObraColleague(id: 'c23', nombre: 'Ignacio Pardo', puesto: 'Operador'),
        ObraColleague(id: 'c24', nombre: 'Lucía Fernández', puesto: 'Seguridad'),
      ],
      productos: [
        ObraProduct(
          id: 'p30',
          nombre: 'Grúa Hidráulica',
          cantidad: 1,
          status: ObraProductStatus.enUso,
        ),
        ObraProduct(
          id: 'p31',
          nombre: 'Generador Eléctrico',
          cantidad: 2,
          status: ObraProductStatus.operativo,
        ),
        ObraProduct(
          id: 'p32',
          nombre: 'Compresor de Aire',
          cantidad: 3,
          status: ObraProductStatus.averiado,
        ),
      ],
    ),
  ];
}
