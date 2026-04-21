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
  Future<User> login({required String email, required String password}) async {
    final result = await _remoteDataSource.login(email: email, password: password);

    await _localStorage.saveToken(result.token);
    await _localStorage.saveRefreshToken(result.refreshToken);
    await _localStorage.saveString(_userKey, jsonEncode(result.user.toJson()));

    return result.user;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    await _remoteDataSource.forgotPassword(email: email);
  }

  @override
  Future<User?> getLoggedUser() async {
    final token = await _localStorage.getToken();
    if (token == null) return null;

    final userJson = await _localStorage.getString(_userKey);
    if (userJson == null) return null;

    return UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  @override
  Future<void> logout() async {
    await _localStorage.clearSession();
    await _localStorage.remove(_userKey);
  }
}
