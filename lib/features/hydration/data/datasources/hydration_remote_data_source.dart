import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/core.dart';
import 'package:bench_profile_app/features/hydration/domain/entities/hydration_log.dart';

abstract class HydrationRemoteDataSource {
  Future<void> logWaterIntake(HydrationLog log);
}

class HydrationRemoteDataSourceImpl implements HydrationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  HydrationRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<void> logWaterIntake(HydrationLog log) async {
    final user = auth.currentUser;

    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final date = log.timestamp;
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // New Path: bench_profile/{userId}/water_logs/{dateId}/logs/{logId}
      final docRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId)
          .collection('logs')
          .doc(log.id);

      final data = {
        'id': log.id,
        'userId': user.uid,
        'timestamp': Timestamp.fromDate(log.timestamp),
        'amountLiters': log.amountLiters,
        'beverageType': log.beverageType,
        'createdAt': log.createdAt != null
            ? Timestamp.fromDate(log.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
