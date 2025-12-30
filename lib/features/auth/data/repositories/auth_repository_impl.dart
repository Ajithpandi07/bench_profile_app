import 'package:firebase_auth/firebase_auth.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/core.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_remote.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthRemote remote;
  AuthRepositoryImpl({required this.remote});

  @override
  Future<Either<Failure, UserProfile>> signInWithEmail(
      {required String email, required String password}) async {
    try {
      final user = await remote.signInWithEmail(email, password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'An unknown error occurred.'));
    } catch (e) {
      // Convert any other exception into a Failure so callers always receive an Either
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() => remote.signOut();

  @override
  Future<Either<Failure, UserProfile>> signUpWithEmail(
      {required String email, required String password}) async {
    try {
      final user = await remote.signUpWithEmail(email, password);
      return Right(user);
    } on FirebaseAuthException catch (e) {
      return Left(ServerFailure(e.message ?? 'An unknown error occurred.'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      await remote.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
