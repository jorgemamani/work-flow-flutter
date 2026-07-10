part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.cuit,
    required this.email,
    required this.password,
  });

  final String cuit;
  final String email;
  final String password;

  @override
  List<Object?> get props => [cuit, email, password];
}

final class AuthForgotPasswordRequested extends AuthEvent {
  const AuthForgotPasswordRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
