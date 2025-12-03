// lib/features/health_metrics/data/datasources/local/health_metrics_local_data_source_isar_impl.dart

import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HealthMetricsLocalDataSourceIsarImpl
    implements HealthMetricsLocalDataSource {
  late final Future<Isar> _db;

  /// Primary constructor: if [isar] is provided it will be used (DI-friendly).
  /// Otherwise the implementation will open an Isar instance itself.
  HealthMetricsLocalDataSourceIsarImpl([Isar? isar]) {
    if (isar != null) {
      _db = Future.value(isar);
    } else {
      _db = _openDB();
    }
  }

  /// Convenience named constructor for tests (explicit).
  HealthMetricsLocalDataSourceIsarImpl.test(Isar isar) : _db = Future.value(isar);

  Future<Isar> _openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [HealthMetricsSchema],
        directory: dir.path,
        name: 'health_metrics_db',
      );
    }
    // Return existing instance if already opened (match the 'name' used above)
    return Future.value(Isar.getInstance('health_metrics_db'));
  }

  @override
  Future<void> cacheHealthMetrics(HealthMetrics metrics) async {
    final isar = await _db;
    await isar.writeTxn(() async {
      await isar.healthMetrics.put(metrics);
    });
  }

  @override
  Future<HealthMetrics> getHealthMetricsForDate(DateTime date) async {
    final isar = await _db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    // Use explicit range to be robust across Isar versions
    final result = await isar.healthMetrics
        .filter()
        .timestampGreaterThan(startOfDay, include: true)
        .timestampLessThan(endOfDay, include: false)
        .findFirst();

    if (result != null) return result;
    throw CacheException();
  }
}
