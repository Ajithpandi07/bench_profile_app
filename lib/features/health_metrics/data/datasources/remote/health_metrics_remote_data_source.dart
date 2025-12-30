import '../../../domain/entities/health_metrics.dart';

/// Data source contract for uploading health metrics to a remote store (e.g., Firestore).
abstract class HealthMetricsRemoteDataSource {
  /// Uploads a list of [HealthMetrics] to the remote store.
  /// Throws a [ServerException] for all errors.
  Future<void> uploadHealthMetrics(List<HealthMetrics> metrics);

  /// Fetches a list of [HealthMetrics] for a specific date from the remote store.
  /// Throws a [ServerException] for all errors.
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date);

  /// NEW: return *all* remote points for the current user
  Future<List<HealthMetrics>> getAllHealthMetricsForUser();
}
