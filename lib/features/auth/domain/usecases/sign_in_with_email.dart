import 'package:dartz/dartz.dart';

import '../../../../core/core.dart';
import '../repositories/auth_repository.dart';
import '../../../auth/domain/entities/user_profile.dart';

class SignInWithEmailParams {
  final String email;
  final String password;
  SignInWithEmailParams({required this.email, required this.password});
}

class SignInWithEmail {
  final AuthRepository repository;
  SignInWithEmail(this.repository);

  Future<Either<Failure, UserProfile>> call(SignInWithEmailParams params) {
    return repository.signInWithEmail(
        email: params.email, password: params.password);
  }
}
