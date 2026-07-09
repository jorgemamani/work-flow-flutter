import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final IAuthRepository _repository;

  Future<User> call({
    required String cuit,
    required String email,
    required String password,
  }) {
    return _repository.login(cuit: cuit, email: email, password: password);
  }
}
