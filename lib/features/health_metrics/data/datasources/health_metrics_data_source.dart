import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

/// Data source contract for fetching new health metrics from the primary source (e.g., health package).
abstract class HealthMetricsDataSource {
  /// Fetches [HealthMetrics] for a specific date.
  ///
  /// Throws a [PermissionDeniedException] if permissions are not granted.
  /// Throws a [ServerException] for other failures.
  Future<HealthMetrics> getHealthMetricsForDate(DateTime date);
}
