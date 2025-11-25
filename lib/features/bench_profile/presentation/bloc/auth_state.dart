import 'package:equatable/equatable.dart';
import '../../domain/entities/user_profile.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserProfile user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user.uid, user.email];
}

class Unauthenticated extends AuthState {}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

class AuthSignUpSuccess extends AuthState {
  final String uid;
  AuthSignUpSuccess(this.uid);
  @override
  List<Object?> get props => [uid];
}
