import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io' show Platform;
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/data/models/health_model.dart';

class HealthMetricsRemoteDataSourceImpl implements HealthMetricsRemoteDataSource {
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
    final userId = auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User is not authenticated. Cannot upload metrics.');
    }
    if (metrics.isEmpty) return;

    // Platform-specific collection name
    final platformCollection = Platform.isIOS ? 'healthmetriceios' : 'healthmetricesandroid';

    final date = metrics.first.dateFrom;
    final docId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // CORRECT: build path by chaining collection/doc/collection/doc
    final summaryDocRef = firestore
        .collection('bench_profile')
        .doc(userId)
        .collection(platformCollection)
        .doc(docId);

    final pointsCollectionRef = summaryDocRef.collection('health_metrics');

    final batch = firestore.batch();

    // Create summary
    final summaryData = aggregator.aggregate(metrics);
    summaryData['timestamp'] = Timestamp.fromDate(DateTime(date.year, date.month, date.day));
    summaryData['source'] = 'health_package';

    batch.set(summaryDocRef, summaryData, SetOptions(merge: true));

    // Add individual points
    for (final metric in metrics) {
      batch.set(pointsCollectionRef.doc(metric.uuid), metric.toMap());
    }

    await batch.commit();
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
      final platformCollection = Platform.isIOS ? 'healthmetriceios' : 'healthmetricesandroid';

      final docId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final pointsCollectionRef = firestore
          .collection('bench_profile')
          .doc(userId)
          .collection(platformCollection)
          .doc(docId)
          .collection('health_metrics');

      final snapshot = await pointsCollectionRef.get();

      if (snapshot.docs.isEmpty) {
        return []; // No data found for this date
      }

      final metrics = snapshot.docs.map((doc) => HealthModel.fromMap(doc.data())).toList();
      return metrics;
    } catch (e) {
      // Wrap Firestore/other errors in a ServerException
      throw ServerException('Failed to fetch remote metrics: ${e.toString()}');
    }
  }
}
