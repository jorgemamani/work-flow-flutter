import 'dart:convert';

import '../../../../core/local_storage/domain/local_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl(this._remoteDataSource, this._localStorage);

  final IAuthRemoteDataSource _remoteDataSource;
  final ILocalStorage _localStorage;

  static const _userKey = 'logged_user';

  @override
  Future<User> login({
    required String cuit,
    required String email,
    required String password,
  }) async {
    final result = await _remoteDataSource.login(
      cuit: cuit,
      email: email,
      password: password,
    );

    // Guardar token antes de /me para que el interceptor lo inyecte.
    await _localStorage.saveToken(result.accessToken);
    await _localStorage.saveRefreshToken(result.refreshToken);

    final user = await _enrichWithMe(result.user);
    await _persistUser(user);
    return user;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<User?> getLoggedUser() async {
    final token = await _localStorage.getToken();
    if (token == null) return null;

    final cached = await _loadCachedUser();
    if (cached == null) return null;

    try {
      final refreshed = await _enrichWithMe(cached);
      await _persistUser(refreshed);
      return refreshed;
    } catch (_) {
      return cached;
    }
  }

  @override
  Future<void> logout() async {
    await _localStorage.clearSession();
    await _localStorage.remove(_userKey);
  }

  Future<UserModel> _enrichWithMe(UserModel baseUser) =>
      _remoteDataSource.getMe(baseUser: baseUser);

  Future<void> _persistUser(UserModel user) async {
    await _localStorage.saveString(_userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> _loadCachedUser() async {
    final userJson = await _localStorage.getString(_userKey);
    if (userJson == null) return null;
    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }
}
