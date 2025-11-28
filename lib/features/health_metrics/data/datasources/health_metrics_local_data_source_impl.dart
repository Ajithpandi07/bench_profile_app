// lib/features/health_metrics/data/datasources/health_metrics_local_data_source_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:health/health.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/models/health_metrics_model.dart';

/// Concrete implementation of HealthMetricsLocalDataSource that:
/// - reads device data using `Health` (if provided)
/// - saves/loads models to Firestore
class HealthMetricsLocalDataSourceImpl implements HealthMetricsLocalDataSource {
  final FirebaseFirestore firestore;
  final Health? health;

  HealthMetricsLocalDataSourceImpl({
    required this.firestore,
    this.health,
  });

  static const String _collection = 'health_metrics';

  // Helper to create a fallback empty model
  HealthMetricsModel _emptyNow() => HealthMetricsModel.empty(DateTime.now());

  // Helper to extract numeric double value from HealthDataPoint (new health package
  // wraps numeric values in NumericHealthValue).
  double? _extractNumericValue(HealthDataPoint dp) {
    final val = dp.value;
    if (val is NumericHealthValue) {
      final numValue = val.numericValue;
      return numValue?.toDouble();
    }
    return null;
  }

  @override
  Future<HealthMetricsModel> fetchHealthData() async {
     final now = DateTime.now();
     final start = now.subtract(const Duration(days: 1));
     final end = start.add(const Duration(hours: 24));

    if (health == null) {
      return HealthMetricsModel.empty(now);
    }

    try {
      final types = <HealthDataType>[

        HealthDataType.STEPS,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        // HealthDataType.EXERCISE_TIME, // Note: Replaces ExerciseSession for aggregation
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

      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final granted = await health!.requestAuthorization(types, permissions: permissions);
      // if (!granted) return HealthMetricsModel.empty(now);

      final points = await health!.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      int totalSteps = 0;
      double heartSum = 0.0;
      int heartCount = 0;
      double? weight;
      double? activeEnergy;

      for (final dp in points) {
        final numeric = _extractNumericValue(dp);
        switch (dp.type) {
          case HealthDataType.STEPS:
            if (numeric != null) totalSteps += numeric.toInt();
            break;
          case HealthDataType.HEART_RATE:
            if (numeric != null) {
              heartSum += numeric;
              heartCount++;
            }
            break;
          case HealthDataType.WEIGHT:
            if (numeric != null) weight = numeric;
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            if (numeric != null) activeEnergy = (activeEnergy ?? 0) + numeric;
            break;
          default:
            break;
        }
      }

      final avgHeartRate = (heartCount > 0) ? (heartSum / heartCount) : null;

      return HealthMetricsModel(
        source: 'device',
        timestamp: now,
        steps: totalSteps,
        heartRate: avgHeartRate,
        weight: weight,
        height: null,
        activeEnergyBurned: activeEnergy,
      );
    } catch (e) {
      return _emptyNow();
    }
  }

  @override
  Future<HealthMetricsModel> fetchHealthDataRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    final now = end;

    if (health == null) return HealthMetricsModel.empty(now);

    try {
      final permissions = types.map((_) => HealthDataAccess.READ).toList();
      final granted = await health!.requestAuthorization(types, permissions: permissions);
      // if (!granted) return HealthMetricsModel.empty(now);

      final points = await health!.getHealthDataFromTypes(
        startTime: start,
        endTime: end,
        types: types,
      );

      int totalSteps = 0;
      double heartSum = 0.0;
      int heartCount = 0;
      double? activeEnergy;

      for (final dp in points) {
        final numeric = _extractNumericValue(dp);
        switch (dp.type) {
          case HealthDataType.STEPS:
            if (numeric != null) totalSteps += numeric.toInt();
            break;
          case HealthDataType.HEART_RATE:
            if (numeric != null) {
              heartSum += numeric;
              heartCount++;
            }
            break;
          case HealthDataType.ACTIVE_ENERGY_BURNED:
            if (numeric != null) activeEnergy = (activeEnergy ?? 0) + numeric;
            break;
          default:
            break;
        }
      }

      final avgHeartRate = (heartCount > 0) ? (heartSum / heartCount) : null;

      return HealthMetricsModel(
        source: 'device',
        timestamp: now,
        steps: totalSteps,
        heartRate: avgHeartRate,
        weight: null,
        height: null,
        activeEnergyBurned: activeEnergy,
      );
    } catch (e) {
      return HealthMetricsModel.empty(now);
    }
  }

  @override
  Future<void> saveHealthMetricsToFirestore(String uid, HealthMetricsModel model) async {
    final docRef = firestore.collection(_collection).doc(uid);
    await docRef.set(model.toFirestore());
  }

  @override
  Future<HealthMetricsModel?> getStoredHealthMetrics(String uid) async {
    final doc = await firestore.collection(_collection).doc(uid).get();
    if (!doc.exists) return null;
    return HealthMetricsModel.fromFirestore(doc);
  }
}
