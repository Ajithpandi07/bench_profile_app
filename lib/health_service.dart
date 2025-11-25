import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'core/util/metric_aggregator.dart';
import 'features/bench_profile/data/datasources/health_data_source.dart';
import 'features/bench_profile/data/models/health_metrics_model.dart';

class HealthService implements HealthDataSource {
  // Use the new v13 Health API
  final Health _health = Health();

  /// The data types to request — extend this list as needed.
  static final List<HealthDataType> types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_AWAKE,
    HealthDataType.WATER,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  ];

  /// Checks if Health Connect is available and installed on the device.
  /// On iOS, this will always return true as it checks for Apple Health.
  Future<bool> isHealthConnectAvailable() async {
    if (Platform.isAndroid) {
      final status = await _health.getHealthConnectSdkStatus();
      return status == HealthConnectSdkStatus.sdkAvailable;
    }
    return true; // Apple Health is always available on iOS
  }

  /// Prompts the user to install Health Connect if it's not available.
  /// Does nothing on iOS.
  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      await _health.installHealthConnect();
    }
  }
  /// Requests authorization for our desired types.
  /// Returns true when permission granted (may be partial on some platforms).
  Future<bool> requestAuthorization() async {
    try {
      return await _health.requestAuthorization(types);
    } catch (e) {
      // log / handle as appropriate
      // print('Authorization error: $e');
      rethrow;
    }
  }

  /// Fetches health data for the last 24 hours and converts to your HealthMetrics entity.
  @override
  Future<HealthMetricsModel> fetchHealthData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final List<HealthMetricsModel> allMetrics = [];

    // First, check if Health Connect is even available
    if (Platform.isAndroid && !(await isHealthConnectAvailable())) {
      return HealthMetricsModel(source: 'none', timestamp: now, steps: 0, heartRate: 0.0);
    }

    final granted = await requestAuthorization();
    if (!granted) {
      // Return empty metrics if permission is not granted.
      return HealthMetricsModel(source: 'none', timestamp: now, steps: 0, heartRate: 0.0);
    }

    try {
      // v13+ uses named parameters
      final List<HealthDataPoint> raw = await _health.getHealthDataFromTypes(
        types: types,
        startTime: yesterday,
        endTime: now,
      );

      // Deduplicate raw points (simple strategy)
      final unique = _removeDuplicates(raw);

      for (final p in unique) {
        // Determine source string
        String source;
        try {
          // If the SDK provides platform info, use it. Fallback to platform check.
          source = p.sourcePlatform == HealthPlatformType.appleHealth ? 'healthkit' : 'health_connect';
        } catch (_) {
          // If sourcePlatform is not available on this version, use platform fallback
          source = Platform.isAndroid ? 'health_connect' : (Platform.isIOS ? 'healthkit' : 'unknown');
        }

        // Convert the flexible HealthValue safely
        final dynamic rawValue = p.value;
        final int? asInt = _toIntOrNull(rawValue);
        final double? asDouble = _toDoubleOrNull(rawValue);

        HealthMetricsModel? metric;

        if (p.type == HealthDataType.STEPS) {
          metric = HealthMetricsModel(
            source: source,
            steps: asInt ?? 0,
            timestamp: p.dateFrom,
          );
        } else if (p.type == HealthDataType.HEART_RATE) {
          metric = HealthMetricsModel(
            source: source,
            heartRate: asDouble,
            timestamp: p.dateFrom,
          );
        } else if (p.type == HealthDataType.WEIGHT) {
          metric = HealthMetricsModel(
              source: source,
              weight: asDouble,
              timestamp: p.dateFrom);
        } else if (p.type == HealthDataType.HEIGHT) {
          metric = HealthMetricsModel(
              source: source,
              height: asDouble,
              timestamp: p.dateFrom);
        } else if (p.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          metric = HealthMetricsModel(
              source: source,
              activeEnergyBurned: asDouble,
              timestamp: p.dateFrom);
        } else if (p.type == HealthDataType.SLEEP_ASLEEP) {
          metric = HealthMetricsModel(
              source: source,
              sleepAsleep: asDouble,
              timestamp: p.dateFrom);
        } else if (p.type == HealthDataType.SLEEP_AWAKE) {
          metric = HealthMetricsModel(
              source: source,
              sleepAwake: asDouble,
              timestamp: p.dateFrom);
        } else if (p.type == HealthDataType.WATER) {
          metric = HealthMetricsModel(
              source: source,
              water: asDouble,
              timestamp: p.dateFrom);
        }

        if (metric != null) allMetrics.add(metric);
      }
    } catch (e) {
      // handle or rethrow as you prefer
      // print('Error fetching health data: $e');
      rethrow;
    }

    final aggregated = aggregateMetrics(allMetrics);
    return HealthMetricsModel(
      source: aggregated.source,
      steps: aggregated.steps,
      heartRate: aggregated.heartRate,
      timestamp: aggregated.timestamp,
      weight: aggregated.weight,
      height: aggregated.height,
      activeEnergyBurned: aggregated.activeEnergyBurned,
      sleepAsleep: aggregated.sleepAsleep,
      sleepAwake: aggregated.sleepAwake,
      water: aggregated.water,
    );
  }

  /// Simple dedupe: keep first occurrence of unique key (type + from + to + value)
  List<HealthDataPoint> _removeDuplicates(List<HealthDataPoint> points) {
    final seen = <String>{};
    final out = <HealthDataPoint>[];

    for (final p in points) {
      final key = '${p.type}-${p.dateFrom.toUtc().toIso8601String()}-${p.dateTo.toUtc().toIso8601String()}-${p.value.toString()}';
      if (!seen.contains(key)) {
        seen.add(key);
        out.add(p);
      }
    }
    return out;
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) {
      final i = int.tryParse(v);
      if (i != null) return i;
      final d = double.tryParse(v);
      if (d != null) return d.toInt();
    }
    if (v is Map) {
      if (v.containsKey('value')) return _toIntOrNull(v['value']);
      if (v.containsKey('quantity')) return _toIntOrNull(v['quantity']);
    }
    return null;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    if (v is Map) {
      if (v.containsKey('value')) return _toDoubleOrNull(v['value']);
      if (v.containsKey('quantity')) return _toDoubleOrNull(v['quantity']);
    }
    return null;
  }
}
