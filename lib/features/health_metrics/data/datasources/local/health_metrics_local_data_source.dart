// lib/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

/// Local data source contract for health metrics.
/// This defines the contract for a local cache.
abstract class HealthMetricsLocalDataSource {
  /// Caches the given [HealthMetrics].
  Future<void> cacheHealthMetrics(HealthMetrics metrics);

  /// Retrieves [HealthMetrics] for a specific date from the cache.
  /// Throws a [CacheException] if no data is found.
  Future<HealthMetrics> getHealthMetricsForDate(DateTime date);
}
