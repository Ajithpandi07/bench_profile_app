import 'dart:io' show Platform;
import 'package:health/health.dart';
import 'core/util/metric_aggregator.dart';
import 'features/bench_profile/data/datasources/health_data_source.dart';
import 'features/bench_profile/data/models/health_metrics_model.dart';
import 'package:flutter/foundation.dart';

class HealthService implements HealthDataSource {
  // Create a single instance of the Health class.
  final Health _health = Health();

  /// Data types to read from Health Connect
  static final List<HealthDataType> _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.BASAL_ENERGY_BURNED,
    HealthDataType.FLIGHTS_CLIMBED,
    HealthDataType.EXERCISE_TIME, // Note: Replaces ExerciseSession for aggregation
    HealthDataType.HEIGHT,
    HealthDataType.WEIGHT,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.BODY_TEMPERATURE,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.WATER,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.RESTING_HEART_RATE,
  ];

  /// Checks if the Health Connect API is supported on the device.
  Future<bool> isApiSupported() async {
    if (!Platform.isAndroid) return false;
    // isApiSupported() is deprecated. We can rely on checkPlatformType.
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Checks if the Health Connect app is installed.
  Future<bool> isHealthConnectAvailable() async {
    if (!Platform.isAndroid) return false;
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Prompts the user to install Health Connect on Android (noop on iOS).
  Future<void> installHealthConnect() async {
    if (Platform.isAndroid) {
      await _health.installHealthConnect();
    }
  }

  /// Requests permissions for the given data types.
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;

    // Check which permissions are already granted
    List<HealthDataType> typesToRequest = [];
    for (final type in _types) {
      final hasPermission = await _health.hasPermissions([type], permissions: [HealthDataAccess.READ]);
      if (hasPermission == null || !hasPermission) {
        typesToRequest.add(type);
      }
    }

    // If we already have all permissions, we are authorized.
    if (typesToRequest.isEmpty) {
      return true;
    }

    // Otherwise, request only the missing permissions.
    debugPrint('Requesting authorization for ${typesToRequest.length} types...');
    final permissionsToRequest = List.filled(typesToRequest.length, HealthDataAccess.READ);

    return await _health.requestAuthorization(typesToRequest, permissions: permissionsToRequest);
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

       final health = Health();

      // configure the health plugin before use.
      await health.configure();


      // define the types to get
      var types = [
        HealthDataType.STEPS,
        HealthDataType.BLOOD_GLUCOSE,
      ];

      // requesting access to the data types before reading them
      final requested = await health.requestAuthorization(types);

    // 2. Request permissions.
    // final bool isAuthorized = await requestPermissions();
    // if (!isAuthorized) {
    //   debugPrint('Authorization denied.');
    //   return HealthMetricsModel.empty(now);
    // }

    // 2a. Pre-emptively check if we have all permissions BEFORE fetching.
    // This is crucial to prevent an internal crash in the health plugin,
    // which incorrectly calls requestAuthorization if it thinks permissions are missing.
    bool allPermissionsGranted = true;
    for (var type in _types) {
      final granted = await _health.hasPermissions([type], permissions: [HealthDataAccess.READ]);
      if (granted == null || !granted) {
        allPermissionsGranted = false;
        break;
      }
    }

    // If the pre-emptive check fails, do not proceed.
    if (!allPermissionsGranted) {
      debugPrint('Pre-emptive permission check failed. Not all permissions are granted.');
      return HealthMetricsModel.empty(now);
    }

    // 3. Fetch the data.
    List<HealthDataPoint> allRecords = [];
    try {

      // await Permission.activityRecognition.request();
      // await Permission.location.request();

      // allRecords = await Permission.activityRecognition.request();
      // allRecords = await Permission.location.request();

      // Global Health instance
      final health = Health();

      // configure the health plugin before use.
      await health.configure();


      // define the types to get
      var types = [
        HealthDataType.STEPS,
        HealthDataType.BLOOD_GLUCOSE,
      ];

      // requesting access to the data types before reading them
      final requested = await health.requestAuthorization(types);

      allRecords = await _health.getHealthDataFromTypes(
        startTime: yesterday,
        endTime: now,
        types: _types,
      );

      // Aggregate the fetched records using MetricAggregator
      final aggregator = MetricAggregator();
      
      // Assuming MetricAggregator has a method 'aggregateRecords' that processes
      // the list of HealthConnectRecord and returns a Map<String, dynamic>
      // or an object with properties matching HealthMetricsModel constructor.
      // For this fix, we'll assume it returns a Map<String, dynamic>.
      final Map<String, dynamic> aggregated = aggregator.aggregateRecords(allRecords);

      return HealthMetricsModel(
        timestamp: now,
        source: 'health_connect',
        steps: _toIntOrNull(aggregated[HealthDataType.STEPS.name]) ?? 0,
        activeEnergyBurned: _toDoubleOrNull(aggregated[HealthDataType.ACTIVE_ENERGY_BURNED.name]),
        basalEnergyBurned: _toDoubleOrNull(aggregated[HealthDataType.BASAL_ENERGY_BURNED.name]),
        flightsClimbed: _toIntOrNull(aggregated[HealthDataType.FLIGHTS_CLIMBED.name]),
        height: _toDoubleOrNull(aggregated[HealthDataType.HEIGHT.name]),
        weight: _toDoubleOrNull(aggregated[HealthDataType.WEIGHT.name]),
        bodyFatPercentage: _toDoubleOrNull(aggregated[HealthDataType.BODY_FAT_PERCENTAGE.name]),
        heartRate: _toDoubleOrNull(aggregated[HealthDataType.HEART_RATE.name]),
        bloodPressureSystolic: _toDoubleOrNull(aggregated[HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name]),
        bloodPressureDiastolic: _toDoubleOrNull(aggregated[HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name]),
        bloodOxygen: _toDoubleOrNull(aggregated[HealthDataType.BLOOD_OXYGEN.name]),
        bloodGlucose: _toDoubleOrNull(aggregated[HealthDataType.BLOOD_GLUCOSE.name]),
        sleepAsleep: _toDoubleOrNull(aggregated[HealthDataType.SLEEP_ASLEEP.name]),
        sleepAwake: _toDoubleOrNull(aggregated[HealthDataType.SLEEP_AWAKE.name]),
        sleepLight: _toDoubleOrNull(aggregated['sleepLight']),
        sleepDeep: _toDoubleOrNull(aggregated['sleepDeep']),
        sleepRem: _toDoubleOrNull(aggregated['sleepRem']),
        restingHeartRate: _toDoubleOrNull(aggregated[HealthDataType.RESTING_HEART_RATE.name]),
        water: _toDoubleOrNull(aggregated[HealthDataType.WATER.name]),
      );
    } catch (e) {
      debugPrint('Error fetching health data: $e');
      return HealthMetricsModel.empty(now);
    }
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
