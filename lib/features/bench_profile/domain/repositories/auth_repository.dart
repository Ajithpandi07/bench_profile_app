import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile.dart';

/// Repository interface for authentication. Keep implementations in data/.
abstract class AuthRepository {
  /// Attempts to sign in with email and password.
  /// Returns UserProfile on success or a Failure on error.
  Future<Either<Failure, UserProfile>> signInWithEmail({required String email, required String password});

  /// Signs out the current user.
  Future<void> signOut();
}
