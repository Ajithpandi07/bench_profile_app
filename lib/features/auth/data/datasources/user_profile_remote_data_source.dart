import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class UserProfileRemoteDataSource {
  Future<UserModel> getUserProfile(String userId);
}

class UserProfileRemoteDataSourceImpl implements UserProfileRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  static const String _collectionName = 'fitnessprofile';

  UserProfileRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
  });

  CollectionReference<Map<String, dynamic>> _getCollection() {
    return firestore.collection(_collectionName);
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final doc = await _getCollection().doc(userId).get();

      if (!doc.exists) {
        // If doc doesn't exist, we might return a basic profile or throw
        // For now, let's assume we want to return what we can from Auth + defaults
        final user = auth.currentUser;
        if (user != null && user.uid == userId) {
          return UserModel(
            uid: userId,
            email: user.email ?? '',
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
        }
        throw ServerException('User profile not found');
      }

      // Merge Firestore data with Auth data (if available and needed)
      // Usually Auth data (displayName, photoUrl) is source of truth for Identity,
      // but fitnessprofile might store overrides.
      // UserModel.fromFirestore handles mapping "target_calroees" etc.

      // We might want to overlay current Auth Details if they are missing in firestore?
      // Or just trust firestore doc + constructor defaults.
      // The fromFirestore factory uses the doc data.
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
