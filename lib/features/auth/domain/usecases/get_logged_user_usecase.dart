import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class GetLoggedUserUseCase {
  GetLoggedUserUseCase(this._repository);

  final IAuthRepository _repository;

  Future<User?> call() {
    return _repository.getLoggedUser();
  }
}
