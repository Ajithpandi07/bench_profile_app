import 'package:isar/isar.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

/// Isar-based local datasource which expects an already-open Isar instance.
/// This implementation assumes your generated Isar accessor is `healthMetrics`
/// as specified in the `@Collection(accessor: 'healthMetrics', ...)`.
class HealthMetricsLocalDataSourceIsarImpl
    implements HealthMetricsLocalDataSource {
  final Isar _isar;

  /// Primary constructor - inject the opened Isar instance (from DI).
  HealthMetricsLocalDataSourceIsarImpl(this._isar);

  /// Named constructor for tests - allows injecting a pre-opened Isar instance.
  HealthMetricsLocalDataSourceIsarImpl.test(Isar isar) : _isar = isar;

  /// Save/replace a HealthMetrics object in Isar.
  @override
  Future<void> cacheHealthMetrics(HealthMetrics metrics) async {
    try {
      await _isar.writeTxn(() async {
        // Check for existing record by UUID to prevent duplicates
        final existing = await _isar.healthMetrics
            .filter()
            .uuidEqualTo(metrics.uuid)
            .findFirst();

        if (existing == null) {
          await _isar.healthMetrics.put(metrics);
        }
      });
    } catch (e, st) {
      // Optionally log e/st for debugging
      throw CacheException();
    }
  }

  /// Return all HealthMetrics entries whose dateFrom lies on the given date.
  @override
  Future<List<HealthMetrics>> getAllHealthMetricsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Use the generated query methods for the `dateFrom` field.
      final results = await _isar.healthMetrics
          .filter()
          .dateFromGreaterThan(startOfDay, include: true)
          .dateFromLessThan(endOfDay, include: false)
          .findAll();

      // Return the results. If no metrics are found for the date, this will be an empty list.
      return results;
    } catch (_) {
      throw CacheException();
    }
  }

  /// Helper: return all metrics in DB (optional, remove if not part of the interface)
  Future<List<HealthMetrics>> getAllMetrics() async {
    try {
      return await _isar.healthMetrics.where().findAll();
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<List<HealthMetrics>> getUnsyncedMetrics({int limit = 50}) async {
    // Find metrics where syncedAt is null.
    return await _isar.healthMetrics
        .filter()
        .syncedAtIsNull()
        .limit(limit)
        .findAll();
  }

  @override
  Future<void> markAsSynced(List<String> uuids) async {
    if (uuids.isEmpty) return;

    try {
      await _isar.writeTxn(() async {
        // Find all the metrics that match the provided UUIDs.
        // Use filter() because 'uuid' is not indexed.
        final metricsToUpdate = await _isar.healthMetrics.filter().group((q) {
          // Start with the first uuid
          var builder = q.uuidEqualTo(uuids.first);
          // Chain subsequent uuids with .or()
          for (var i = 1; i < uuids.length; i++) {
            builder = builder.or().uuidEqualTo(uuids[i]);
          }
          return builder;
        }).findAll();

        // Create updated copies with the current timestamp.
        final now = DateTime.now();
        final updatedMetrics =
            metricsToUpdate.map((m) => m.copyWith(syncedAt: now)).toList();

        // Bulk-update the records in the database.
        if (updatedMetrics.isNotEmpty) {
          await _isar.healthMetrics.putAll(updatedMetrics);
        }
      });
    } catch (e) {
      throw CacheException('Failed to mark metrics as synced: $e');
    }
  }

  @override
  Future<HealthMetrics?> getLatestMetric() async {
    try {
      // Sort by `dateTo` descending and take the first one.
      return await _isar.healthMetrics.where().sortByDateToDesc().findFirst();
    } catch (e) {
      throw CacheException('Failed to get the latest metric: $e');
    }
  }

  @override
  Future<void> cacheHealthMetricsBatch(List<HealthMetrics> metrics) async {
    if (metrics.isEmpty) return;

    try {
      await _isar.writeTxn(() async {
        final metricsToSave = <HealthMetrics>[];
        for (final metric in metrics) {
          // Check for existing record by UUID
          final existing = await _isar.healthMetrics
              .filter()
              .uuidEqualTo(metric.uuid)
              .findFirst();

          if (existing != null) {
            // Update existing record: reuse the Isar ID so it overwrites
            metricsToSave.add(metric.copyWith(id: existing.id));
          } else {
            // New record: use the metric as-is (id will be auto-increment)
            metricsToSave.add(metric);
          }
        }
        if (metricsToSave.isNotEmpty) {
          await _isar.healthMetrics.putAll(metricsToSave);
        }
      });
    } catch (e) {
      throw CacheException('Failed to batch cache metrics: $e');
    }
  }

  @override
  Future<List<HealthMetrics>> getMetricsForDateRange(
      DateTime start, DateTime end) async {
    try {
      // Use a query to find all metrics within the date range.
      final results = await _isar.healthMetrics
          .filter()
          .dateFromGreaterThan(start, include: true)
          .dateFromLessThan(end, include: false)
          .findAll();

      return results;
    } catch (e) {
      throw CacheException('Failed to get metrics for date range: $e');
    }
  }

  // In lib/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart
// Add these methods to your existing Isar impl (adjust imports & class name accordingly).

  @override
  Future<void> clearAllLocalMetrics() async {
    final isar = _isar;
    try {
      await isar.writeTxn(() async {
        await isar.healthMetrics.clear();
      });
    } catch (e) {
      throw CacheException();
    }
  }
}
