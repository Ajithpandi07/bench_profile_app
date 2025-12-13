// lib/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart

import 'dart:developer' as dev;
import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'health_metrics_data_source.dart';
import '../../domain/entities/health_metrics.dart';

class HealthMetricsDataSourceImpl implements HealthMetricsDataSource {
  final Health _health;
  final MetricAggregator? _aggregator;

  HealthMetricsDataSourceImpl({
    required Health health,
    MetricAggregator? aggregator,
  })  : _health = health,
        _aggregator = aggregator;

  /// Try to fetch points using the named-parameter form that recent `health`
  /// package versions provide. Always supplies `types`.
  Future<List<HealthDataPoint>> _fetchPoints(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    final List<HealthDataPoint> allPoints = [];
    if (types.isEmpty) return allPoints;

    try {
      // Preferred: named-parameter API (most common in modern health package)
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
      allPoints.addAll(points);
      return allPoints;
    } catch (e) {
      dev.log('Primary getHealthDataFromTypes(named) failed: $e', name: 'HealthDataSource');

      // Fallback: try per-type using the named API (still passes 'types')
      for (final t in types) {
        try {
          final pts = await _health.getHealthDataFromTypes(
            startTime: start,
            endTime: end,
            types: [t],
          );
          allPoints.addAll(pts);
        } catch (e2) {
          dev.log('Per-type named fetch failed for $t: $e2', name: 'HealthDataSource');
          // ignore this type and continue with others
        }
      }

      return allPoints;
    }
  }

  List<HealthMetrics> _mapAndDeduplicate(List<HealthDataPoint> points) {
    final mapped = points.map((p) {
      try {
        return HealthMetrics.fromHealthDataPoint(p);
      } catch (e, st) {
        dev.log('Failed mapping point to HealthMetrics: $e\n$st', name: 'HealthDataSource');
        return null;
      }
    }).whereType<HealthMetrics>().toList();

    final Map<String, HealthMetrics> byUuid = {};
    for (final m in mapped) {
      final existing = byUuid[m.uuid];
      if (existing == null || m.dateFrom.isAfter(existing.dateFrom)) {
        byUuid[m.uuid] = m;
      }
    }
    return byUuid.values.toList();
  }

  List<HealthDataType> _platformDefaultTypes() {
    final common = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.WATER,
      HealthDataType.FLIGHTS_CLIMBED,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
    ];

    final androidSpecific = <HealthDataType>[
      HealthDataType.BASAL_ENERGY_BURNED,
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.RESPIRATORY_RATE,
    ];

    final iosSpecific = <HealthDataType>[
      HealthDataType.BASAL_ENERGY_BURNED,
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      // Sleep stage enums may not exist in some versions; remove if you get errors.
      // HealthDataType.SLEEP_IN_BED,
      // HealthDataType.SLEEP_LIGHT,
      // HealthDataType.SLEEP_DEEP,
      // HealthDataType.SLEEP_REM,
    ];

    final merged = <HealthDataType>{...common};
    if (Platform.isAndroid) merged.addAll(androidSpecific);
    if (Platform.isIOS) merged.addAll(iosSpecific);
    return merged.toList();
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final defaultTypes = _platformDefaultTypes();

    try {
      final points = await _fetchPoints(start, end, defaultTypes);
      final metrics = _mapAndDeduplicate(points);
      return metrics;
    } on Exception catch (e) {
      dev.log('Error in getHealthMetricsForDate: $e', name: 'HealthDataSource');
      if (e.toString().toLowerCase().contains('permission') ||
          e.toString().toLowerCase().contains('denied')) {
        throw PermissionDeniedException();
      }
      return <HealthMetrics>[];
    }
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    final queryTypes = types.isEmpty ? _platformDefaultTypes() : types;

    try {
      final points = await _fetchPoints(start, end, queryTypes);
      final metrics = _mapAndDeduplicate(points);
      return metrics;
    } on Exception catch (e) {
      dev.log('Error in getHealthMetricsRange: $e', name: 'HealthDataSource');
      if (e.toString().toLowerCase().contains('permission') ||
          e.toString().toLowerCase().contains('denied')) {
        throw PermissionDeniedException();
      }
      return <HealthMetrics>[];
    }
  }
}
