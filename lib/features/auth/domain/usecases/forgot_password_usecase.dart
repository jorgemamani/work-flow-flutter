import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repository);

  final IAuthRepository _repository;

  Future<void> call({required String email}) {
    return _repository.forgotPassword(email: email);
  }
}
