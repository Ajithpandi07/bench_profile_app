import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/core.dart';
import 'package:bench_profile_app/features/hydration/domain/entities/hydration_log.dart';
import 'package:bench_profile_app/features/hydration/domain/entities/hydration_daily_summary.dart';

abstract class HydrationRemoteDataSource {
  Future<void> logWaterIntake(HydrationLog log);
  Future<List<HydrationLog>> getHydrationLogsForDate(DateTime date);
  Future<List<HydrationDailySummary>> getHydrationStats(
    DateTime startDate,
    DateTime endDate,
  );
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

      // 1b. Update daily total liters
      final dateDocRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId);

      await dateDocRef.set({
        'totalLiters': FieldValue.increment(log.amountLiters),
        'date': Timestamp.fromDate(
          DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await docRef.set(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HydrationLog>> getHydrationLogsForDate(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final querySnapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HydrationLog(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          amountLiters: (data['amountLiters'] as num?)?.toDouble() ?? 0.0,
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          beverageType: data['beverageType'] ?? 'Regular',
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          updatedAt: data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HydrationDailySummary>> getHydrationStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      // Query water_logs collection where date is within range
      // Path: bench_profile/{userId}/water_logs
      // Note: We need to filter by 'date' field which we added in logWaterIntake

      final querySnapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HydrationDailySummary(
          date: (data['date'] as Timestamp).toDate(),
          totalLiters: (data['totalLiters'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
