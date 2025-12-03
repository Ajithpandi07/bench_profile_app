// lib/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart

import 'package:isar/isar.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

class HealthMetricsLocalDataSourceIsarImpl
    implements HealthMetricsLocalDataSource {
  final Isar _isar;

  /// Default constructor - inject the Isar instance (from DI).
  HealthMetricsLocalDataSourceIsarImpl(this._isar);

  /// Named constructor for tests - allows injecting a pre-opened Isar instance.
  HealthMetricsLocalDataSourceIsarImpl.test(this._isar);

  @override
  Future<void> cacheHealthMetrics(HealthMetrics metrics) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.healthMetrics.put(metrics);
      });
    } catch (e) {
      // Map any DB error to your app-specific exception
      throw CacheException();
    }
  }

  @override
  Future<HealthMetrics> getHealthMetricsForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _isar.healthMetrics
          .filter()
          .timestampGreaterThan(startOfDay, include: true)
          .timestampLessThan(endOfDay, include: false)
          .findFirst();

      if (result != null) return result;
      throw CacheException();
    } catch (e) {
      // If you want more specific mapping, inspect `e` here
      throw CacheException();
    }
  }
}
