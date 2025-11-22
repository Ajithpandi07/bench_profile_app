import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_remote.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthRemote remote;
  AuthRepositoryImpl({required this.remote});
  
  @override
  Future<Either<Failure, UserProfile>> signInWithEmail({required String email, required String password}) async {
    try {
      final user = await remote.signInWithEmail(email, password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'An unknown error occurred.'));
    }
  }

  @override
  Future<void> signOut() => remote.signOut();
}
