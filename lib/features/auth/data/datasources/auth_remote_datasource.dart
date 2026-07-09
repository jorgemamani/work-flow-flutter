import '../../../../core/http_client/domain/http_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../models/user_model.dart';

/// Resultado del flujo de login (antes de enriquecer con `/auth/me`).
typedef AuthLoginResult = ({
  UserModel user,
  String accessToken,
  String refreshToken,
});

abstract class IAuthRemoteDataSource {
  /// Flujo multitenant:
  /// 1. `GET /tenants/resolve?cuit=` → tenantId
  /// 2. `POST /auth/login` con `x-tenant-id`
  Future<AuthLoginResult> login({
    required String cuit,
    required String email,
    required String password,
  });

  /// Permisos, scope y estado actual (`GET /auth/me`).
  /// Requiere token guardado (interceptor lo inyecta).
  Future<UserModel> getMe({required UserModel baseUser});

  Future<void> forgotPassword({required String email});
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<AuthLoginResult> login({
    required String cuit,
    required String email,
    required String password,
  }) async {
    final resolveResponse = await _httpClient.get(
      ApiEndpoints.resolveTenant,
      queryParameters: {'cuit': cuit},
    ) as Map<String, dynamic>;

    final tenantId =
        ApiResponseParser.unwrap(resolveResponse)['id'] as String;

    final loginResponse = await _httpClient.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
      headers: {'x-tenant-id': tenantId},
    ) as Map<String, dynamic>;

    final data = ApiResponseParser.unwrap(loginResponse);
    final user = UserModel.fromAuthUserDto(
      data['user'] as Map<String, dynamic>,
    );

    return (
      user: user,
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  @override
  Future<UserModel> getMe({required UserModel baseUser}) async {
    final response = await _httpClient.get(ApiEndpoints.me) as Map<String, dynamic>;
    final data = ApiResponseParser.unwrap(response);
    return baseUser.applyMeResponse(data);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _httpClient.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }
}
