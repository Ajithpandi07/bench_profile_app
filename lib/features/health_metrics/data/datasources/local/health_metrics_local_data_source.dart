// lib/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

/// Local data source contract for health metrics.
/// This defines the contract for a local cache.
abstract class HealthMetricsLocalDataSource {
  /// Caches the given [HealthMetrics].
  Future<void> cacheHealthMetrics(HealthMetrics metrics);

  /// Retrieves [HealthMetrics] for a specific date from the cache.
  /// Throws a [CacheException] if no data is found.
  Future<List<HealthMetrics>> getAllHealthMetricsForDate(DateTime date);

  // Fetches a batch of metrics that have not yet been synced.
  Future<List<HealthMetrics>> getUnsyncedMetrics({int limit = 50});

  /// Marks a list of metrics as synced by their UUIDs.
  Future<void> markAsSynced(List<String> uuids);

  /// Retrieves all [HealthMetrics] within a specific date range.
  Future<List<HealthMetrics>> getMetricsForDateRange(DateTime start, DateTime end);

  /// Caches a list of [HealthMetrics] in a single transaction.
  Future<void> cacheHealthMetricsBatch(List<HealthMetrics> metrics);
}
