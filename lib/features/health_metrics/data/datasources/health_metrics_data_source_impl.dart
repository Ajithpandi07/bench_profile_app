// lib/features/health_metrics/data/datasources/health_metrics_data_source_impl.dart

import 'package:health/health.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'health_metrics_data_source.dart';
import '../../domain/entities/health_metrics.dart';

/// Concrete implementation of [HealthMetricsDataSource] that talks to the
/// device/platform via the `health` package.
///
/// It expects an already-created [Health] instance (inject via DI) and an
/// optional [MetricAggregator] if you want to pre-aggregate data.
class HealthMetricsDataSourceImpl implements HealthMetricsDataSource {
  final Health _health;
  final MetricAggregator? _aggregator;

  HealthMetricsDataSourceImpl({
    required Health health,
    MetricAggregator? aggregator,
  })  : _health = health,
        _aggregator = aggregator;

  /// Helper to fetch raw HealthDataPoints for a set of types between start/end.
  /// This uses `getHealthDataFromTypes` provided by the `health` package (common API).
  /// If your `health` package version uses a different method name, replace the call here.
  Future<List<HealthDataPoint>> _fetchPoints(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    final List<HealthDataPoint> allPoints = [];

    if (types.isEmpty) return allPoints;

    // The health package usually allows fetching multiple types at once:
    try {
      final points = await _health.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );
      allPoints.addAll(points);
    } catch (e) {
      // Some platforms or package versions may not support multi-type fetch;
      // fallback to fetching per-type to be resilient.
      for (final t in types) {
        try {
          final pts = await _health.getHealthDataFromTypes(
                      startTime: start,
                      endTime: end,
                      types: [t],
                    );

          // final pts = await _health.getHealthDataFromTypes(start, end, [t]);
          allPoints.addAll(pts);
        } catch (_) {
          // ignore errors for individual types and continue
        }
      }
    }

    return allPoints;
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // Default set of types to fetch — change to suit your app.
    final defaultTypes = <HealthDataType>[
      HealthDataType.STEPS,
      HealthDataType.HEART_RATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      // add others you care about
    ];

    final points = await _fetchPoints(start, end, defaultTypes);

    // Map each HealthDataPoint to your domain entity using the factory you already created.
    final metrics = points.map((p) => HealthMetrics.fromHealthDataPoint(p)).toList();

    return metrics;
  }

  @override
  Future<List<HealthMetrics>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    final queryTypes = types.isEmpty
        ? <HealthDataType>[
            HealthDataType.STEPS,
            HealthDataType.HEART_RATE,
            HealthDataType.ACTIVE_ENERGY_BURNED,
          ]
        : types;

    final points = await _fetchPoints(start, end, queryTypes);

    final metrics = points.map((p) => HealthMetrics.fromHealthDataPoint(p)).toList();

    return metrics;
  }
}
