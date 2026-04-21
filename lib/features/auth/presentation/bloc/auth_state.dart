part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

final class AuthInitial extends AuthState {
  const AuthInitial();
}

final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user});

  final User user;

  @override
  List<Object?> get props => [user];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final class AuthLoginFailure extends AuthState {
  const AuthLoginFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}

final class AuthForgotPasswordLoading extends AuthState {
  const AuthForgotPasswordLoading();
}

final class AuthForgotPasswordSuccess extends AuthState {
  const AuthForgotPasswordSuccess();
}

final class AuthForgotPasswordFailure extends AuthState {
  const AuthForgotPasswordFailure({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
