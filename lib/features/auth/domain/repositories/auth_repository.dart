import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user_profile.dart';

/// Repository interface for authentication. Keep implementations in data/.
abstract class AuthRepository {
  /// Attempts to sign in with email and password.
  /// Returns UserProfile on success or a Failure on error.
  Future<Either<Failure, UserProfile>> signInWithEmail({required String email, required String password});

  /// Signs out the current user.
  Future<void> signOut();

  /// Create a new user account with email/password.
  Future<Either<Failure, UserProfile>> signUpWithEmail({required String email, required String password});

  /// Send a password reset email to the given address.
  Future<Either<Failure, void>> sendPasswordReset(String email);
}
