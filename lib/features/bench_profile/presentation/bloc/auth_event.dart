import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  SignInRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  SignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;
  ForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}
