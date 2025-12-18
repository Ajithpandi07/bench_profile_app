import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/data/models/health_model.dart';

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

  @override
  Future<void> uploadHealthMetrics(List<HealthMetrics> metrics) async {
    try {
      final userId = auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User is not authenticated. Cannot upload metrics.');
      }
      if (metrics.isEmpty) return;

      final platformCollection =
          Platform.isIOS ? 'healthmetriceios' : 'healthmetricesandroid';

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
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));

        final summaryDocRef = firestore
            .collection('bench_profile')
            .doc(userId)
            .collection(platformCollection)
            .doc(docId);

        final pointsCollectionRef = summaryDocRef.collection('health_metrics');

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
      // Or return empty list if this is not considered an exception
      throw ServerException('User is not authenticated.');
    }

    try {
      // Platform-specific collection name
      final platformCollection =
          Platform.isIOS ? 'healthmetriceios' : 'healthmetricesandroid';

      final docId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final pointsCollectionRef = firestore
          .collection('bench_profile')
          .doc(userId)
          .collection(platformCollection)
          .doc(docId)
          .collection('health_metrics');

      final snapshot = await pointsCollectionRef.orderBy('dateFrom').get();

      if (snapshot.docs.isEmpty) {
        return []; // No data found for this date
      }

      final metrics =
          snapshot.docs.map((doc) => HealthModel.fromMap(doc.data())).toList();
      return metrics;
    } catch (e) {
      // Wrap Firestore/other errors in a ServerException
      throw ServerException('Failed to fetch remote metrics: ${e.toString()}');
    }
  }

  // lib/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source_impl.dart

  @override
  Future<List<HealthMetrics>> getAllHealthMetricsForUser() async {
    final userId = auth.currentUser?.uid;
    if (userId == null) throw ServerException('User is not authenticated.');

    final platformCollection =
        Platform.isIOS ? 'healthmetriceios' : 'healthmetricesandroid';
    final parentRef = firestore
        .collection('bench_profile')
        .doc(userId)
        .collection(platformCollection);

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
