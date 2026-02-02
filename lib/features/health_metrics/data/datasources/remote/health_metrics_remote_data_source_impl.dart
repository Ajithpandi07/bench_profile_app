import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../core/core.dart';

import '../../../domain/entities/entities.dart';
import 'health_metrics_remote_data_source.dart';
import '../../models/models.dart';

class HealthMetricsRemoteDataSourceImpl
    implements HealthMetricsRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final MetricAggregator aggregator;

  HealthMetricsRemoteDataSourceImpl({
    required this.firestore,
    required this.auth,
    required this.aggregator,
  });

  static const String _collectionName = 'fitnessprofile';

  CollectionReference<Map<String, dynamic>> _getPlatformCollectionReference(
    String userId,
  ) {
    final platformCollection = Platform.isIOS
        ? 'healthmetriceios'
        : 'healthmetricesandroid';
    return firestore
        .collection(_collectionName)
        .doc(userId)
        .collection(platformCollection);
  }

  @override
  Future<void> uploadHealthMetrics(List<HealthMetrics> metrics) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User is not authenticated. Cannot upload metrics.');
      }
      if (metrics.isEmpty) return;

      // Platform collection logic moved to helper

      // Group metrics by day to ensure they go into the correct document
      final Map<String, List<HealthMetrics>> groupedByDate = {};
      for (final m in metrics) {
        final dateKey =
            '${m.dateFrom.year}-${m.dateFrom.month.toString().padLeft(2, '0')}-${m.dateFrom.day.toString().padLeft(2, '0')}';
        groupedByDate.putIfAbsent(dateKey, () => []).add(m);
      }

      for (final entry in groupedByDate.entries) {
        final docId = entry.key;
        final dailyMetrics = entry.value;
        // Parse date from key for the summary timestamp
        final parts = docId.split('-');
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );

        final summaryDocRef = _getPlatformCollectionReference(
          userId,
        ).doc(docId);

        // final pointsCollectionRef = summaryDocRef.collection('health_metrics');

        // Create summary for THIS day
        // Note: Ideally we should fetch existing summary and merge, but 'aggregator.aggregate' usually just sums the list passed.
        // If we only upload partial data, the summary might be incomplete if we overwrite.
        // But for now, we follow the previous pattern of SetOptions(merge: true).
        // A better approach would be to recalculate summary from ALL metrics for the day, but that requires a read.
        // We will stick to the existing "blind merge" logic but scoped to the correct day.

        final rawSummaryData = aggregator.aggregate(dailyMetrics);
        final summaryData = rawSummaryData.map((key, value) {
          if (value is MetricValue) {
            return MapEntry(key, {'value': value.value, 'unit': value.unit});
          }
          return MapEntry(key, value);
        });

        summaryData['timestamp'] = Timestamp.fromDate(date);
        summaryData['source'] = 'health_package';
        summaryData['updatedAt'] = FieldValue.serverTimestamp();

        // Write summary only - Disabled individual metric write
        // Check if doc exists to set createdAt only once
        final docSnap = await summaryDocRef.get();
        if (!docSnap.exists) {
          summaryData['createdAt'] = FieldValue.serverTimestamp();
        }

        await summaryDocRef.set(summaryData, SetOptions(merge: true));

        // OLD LOGIC: Writing individual metrics
        /*
        const int batchSize = 450;
        for (var i = 0; i < dailyMetrics.length; i += batchSize) {
          final batch = firestore.batch();
          final end = (i + batchSize < dailyMetrics.length)
              ? i + batchSize
              : dailyMetrics.length;
          final chunk = dailyMetrics.sublist(i, end);

          // Write summary only in the first batch of this day
          if (i == 0) {
            batch.set(summaryDocRef, summaryData, SetOptions(merge: true));
          }

          for (final metric in chunk) {
            batch.set(pointsCollectionRef.doc(metric.uuid), metric.toMap());
          }
          await batch.commit();
        }
        */
      }
    } catch (e) {
      print('Error uploading metrics: $e');
      throw ServerException('Failed to upload metrics: $e');
    }
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw ServerException('User is not authenticated.');
    }

    try {
      final docId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final pointsCollectionRef = _getPlatformCollectionReference(
        userId,
      ).doc(docId).collection('health_metrics');

      final snapshot = await pointsCollectionRef.orderBy('dateFrom').get();
      final healthMetrics = snapshot.docs
          .map((doc) => HealthModel.fromMap(doc.data()))
          .toList();

      return healthMetrics;
    } catch (e) {
      throw ServerException('Failed to fetch remote metrics: ${e.toString()}');
    }
  }

  @override
  Future<List<HealthMetrics>> getAllHealthMetricsForUser() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) throw ServerException('User is not authenticated.');

    final parentRef = _getPlatformCollectionReference(userId);

    final snapshot = await parentRef.get();
    final allPoints = <HealthMetrics>[];

    for (final doc in snapshot.docs) {
      // each doc is a daily summary; it has nested 'health_metrics' collection
      final pointsRef = doc.reference.collection('health_metrics');
      final pointsSnap = await pointsRef.get();
      for (final p in pointsSnap.docs) {
        final map = p.data();
        // You need a fromMap constructor for HealthMetrics model
        final model = HealthMetrics.fromMap(map); // implement this
        allPoints.add(model);
      }
    }
    return allPoints;
  }
}
