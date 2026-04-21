import '../entities/user.dart';

abstract class IAuthRepository {
  Future<User> login({required String email, required String password});
  Future<void> forgotPassword({required String email});
  Future<User?> getLoggedUser();
  Future<void> logout();
}
