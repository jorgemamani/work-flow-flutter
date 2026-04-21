import 'dart:convert';

import '../../../../core/http_client/domain/http_client.dart';
import '../models/user_model.dart';

abstract class IAuthRemoteDataSource {
  Future<({UserModel user, String token, String refreshToken})> login({
    required String email,
    required String password,
  });

  Future<void> forgotPassword({required String email});
}

class AuthRemoteDataSourceImpl implements IAuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<({UserModel user, String token, String refreshToken})> login({
    required String email,
    required String password,
  }) async {
    final response = await _httpClient.post(
      '/auth/login',
      data: jsonEncode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    ) as Map<String, dynamic>;

    final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
    final token = response['token'] as String;
    final refreshToken = response['refresh_token'] as String;

    return (user: user, token: token, refreshToken: refreshToken);
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _httpClient.post(
      '/auth/forgot-password',
      data: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
