// lib/features/health_metrics/data/datasources/health_metrics_data_source.dart

import 'package:health/health.dart';
import '../../domain/entities/health_metrics.dart';

/// Data source contract for fetching health metrics from the device/platform.
abstract class HealthMetricsDataSource {
  /// Return list of metrics captured for [date] (the implementation decides grouping).
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date);

  /// Return all health data points in the range [start]..[end] for the given types.
  /// Implementations should return an empty list if nothing is available.
  Future<List<HealthMetrics>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  );
}
