import 'dart:io' show Platform;
import 'package:flutter_health_connect/flutter_health_connect.dart';
import 'core/util/metric_aggregator.dart';
import 'features/bench_profile/data/datasources/health_data_source.dart';
import 'features/bench_profile/data/models/health_metrics_model.dart';
import 'package:flutter/foundation.dart';

class HealthService implements HealthDataSource {
  /// Data types to read from Health Connect
  static final List<HealthConnectDataType> _types = [
    HealthConnectDataType.Steps,
    HealthConnectDataType.ActiveCaloriesBurned,
    HealthConnectDataType.BasalMetabolicRate,
    HealthConnectDataType.FloorsClimbed,
    HealthConnectDataType.ExerciseSession,
    HealthConnectDataType.Height,
    HealthConnectDataType.Weight,
    HealthConnectDataType.BodyFat,
    HealthConnectDataType.BodyTemperature,
    HealthConnectDataType.HeartRate,
    HealthConnectDataType.BloodPressure,
    HealthConnectDataType.OxygenSaturation,
    HealthConnectDataType.BloodGlucose,
    HealthConnectDataType.RespiratoryRate,
    HealthConnectDataType.Hydration,
    HealthConnectDataType.SleepSession,
    HealthConnectDataType.SleepStage,
    HealthConnectDataType.RestingHeartRate,
  ];

  /// Checks if the Health Connect API is supported on the device.
  Future<bool> isApiSupported() async {
    if (!Platform.isAndroid) return false;
    return await HealthConnectFactory.isApiSupported();
  }

  /// Checks if the Health Connect app is installed.
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    return await HealthConnectFactory.isAvailable();
  }

  /// Prompts the user to install Health Connect on Android (noop on iOS).
  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      await HealthConnectFactory.installHealthConnect();
    }
  }

  /// Requests permissions for the given data types.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;
    final result = await HealthConnectFactory.requestPermissions(
      _types,
      readOnly: true, // We are only reading data
    );
    debugPrint('requestPermissions result: $result');
    return result;
  }

  /// Fetches health data for the last 24 hours and converts to your HealthMetrics entity.
  /// Implements HealthDataSource.fetchHealthData()
  @override
  Future<HealthMetricsModel> fetchHealthData() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 10));

    // 1. Check if Health Connect is available and installed.
    if (Platform.isAndroid && !(await isHealthConnectAvailable())) {
      debugPrint('Health Connect not available, prompting install.');
      await installHealthConnect();
      return HealthMetricsModel.empty(now);
    }

    // 2. Request permissions.
    final bool isAuthorized = await requestPermissions();
    if (!isAuthorized) {
      debugPrint('Authorization denied.');
      return HealthMetricsModel.empty(now);
    }

    // 3. Fetch the data.
    try {
      final records = await HealthConnectFactory.getRecord(
        types: _types,
        startTime: yesterday,
        endTime: now,
      );

      sleepRem: aggregated.sleepRem,
      restingHeartRate: aggregated.restingHeartRate,
    );
  }

  int? _toIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return (v as num).toInt();
    if (v is String) {
      final i = int.tryParse(v);
      if (i != null) return i;
      final d = double.tryParse(v);
      if (d != null) return d.toInt();
    }
    return null;
  }

  double? _toDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return (v as num).toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
