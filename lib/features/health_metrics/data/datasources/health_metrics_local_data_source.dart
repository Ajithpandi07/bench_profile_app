// lib/features/health_metrics/data/datasources/health_metrics_local_data_source.dart

import 'package:health/health.dart';
import '../models/health_metrics_model.dart';

/// Local data source contract for health metrics.
abstract class HealthMetricsLocalDataSource {
  /// Fetch latest aggregated health metrics from the device (e.g., last 24 hours).
  /// Should return a [HealthMetricsModel] populated with values (never null).
  Future<HealthMetricsModel> fetchHealthData();

  /// Fetch aggregated metrics for a given date range and set of [HealthDataType]s.
  Future<HealthMetricsModel> fetchHealthDataRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  );

  /// Save a [HealthMetricsModel] for a given user id (e.g., upload to Firestore).
  Future<void> saveHealthMetricsToFirestore(String uid, HealthMetricsModel model);

  /// Load the last stored health metrics for the user from Firestore (or return null).
  Future<HealthMetricsModel?> getStoredHealthMetrics(String uid);
}
