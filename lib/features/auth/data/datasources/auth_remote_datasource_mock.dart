import '../../../../config/mock_auth_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../shared/enums/user_role.dart';
import '../../../../shared/enums/user_type.dart';
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

    const user = UserModel(
      id: 'mock-local-user',
      name: 'Usuario local (mock)',
      email: MockAuthConfig.email,
      type: UserType.employee,
      role: UserRole.role1,
      avatarUrl: null,
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
