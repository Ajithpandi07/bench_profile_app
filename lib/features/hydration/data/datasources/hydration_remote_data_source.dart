import 'dart:io' show Platform;

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
    print('DEBUG: Current User: ${user?.uid}');
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final platformCollection = Platform.isIOS
          ? 'healthmetriceios'
          : 'healthmetricesandroid';

      final date = log.timestamp; // Use the log's timestamp
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final path =
          'bench_profile/${user.uid}/$platformCollection/$dateId/health_metrics/${log.id}';
      print('DEBUG: Attempting to write to: $path');

      final docRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection(platformCollection)
          .doc(dateId)
          .collection('health_metrics')
          .doc(log.id);

      // Map HydrationLog to HealthMetrics Schema
      final data = {
        'id': 0, // Isar ID (auto-increment), 0 for remote-only/new
        'uuid': log.id,
        'type': 'WATER', // HealthDataType.WATER string equivalent
        'value': log.amountLiters,
        'unit': 'LITER', // HealthDataUnit.LITER string equivalent
        'dateFrom': Timestamp.fromDate(log.timestamp),
        'dateTo': Timestamp.fromDate(log.timestamp),
        'sourceName': 'Manual (${log.beverageType})',
        'sourceId': 'hydration_${log.id}',
        'syncedAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);
      print('DEBUG: Write successful');
    } catch (e) {
      print('DEBUG: Write failed: $e');
      throw ServerException(e.toString());
    }
  }
}
