// lib/features/bench_profile/domain/entities/health_metrics.dart
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';
import 'package:health/health.dart';
part 'health_metrics.g.dart';

@Collection(ignore: {'props', 'stringify'}, inheritance: false)
class HealthMetrics extends Equatable {
  Id id = Isar.autoIncrement; // Make Id non-final
  final String source;
  final int steps;
  final double? heartRate;
  final double? weight;
  final double? height;
  final double? activeEnergyBurned;
  final double? sleepAsleep;
  final double? sleepAwake;
  final double? water;
  final double? bloodOxygen;
  final double? basalEnergyBurned;
  final int? flightsClimbed;
  final double? distanceWalkingRunning;
  final double? bodyFatPercentage;
  final double? bodyMassIndex;
  final double? heartRateVariabilitySdnn;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? bloodGlucose;
  final double? dietaryEnergyConsumed;
  final double? sleepInBed;
  final double? sleepDeep;
  final double? sleepLight;
  final double? sleepRem;
  final double? restingHeartRate;
  final double? caloriesBurned;
  @Index() // Add an index for faster date-based queries
  final DateTime timestamp;

  HealthMetrics({
    required this.source,
    this.steps = 0,
    this.heartRate,
    this.weight,
    this.height,
    this.activeEnergyBurned,
    this.sleepAsleep,
    this.sleepAwake,
    this.water,
    this.bloodOxygen,
    this.basalEnergyBurned,
    this.flightsClimbed,
    this.distanceWalkingRunning,
    this.bodyFatPercentage,
    this.bodyMassIndex,
    this.heartRateVariabilitySdnn,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.bloodGlucose,
    this.dietaryEnergyConsumed,
    this.sleepInBed,
    this.sleepDeep,
    this.sleepLight,
    this.sleepRem,
    this.restingHeartRate,
    this.caloriesBurned,
    required this.timestamp,
  });

  /// Factory constructor to create a HealthMetrics instance from an aggregated map.
  factory HealthMetrics.fromAggregatedMap(Map<String, dynamic> map, DateTime date) {
    return HealthMetrics(
      source: 'health_package',
      timestamp: date,
      steps: (map[HealthDataType.STEPS.name] as double?)?.toInt() ?? 0,
      heartRate: map[HealthDataType.HEART_RATE.name],
      weight: map[HealthDataType.WEIGHT.name],
      height: map[HealthDataType.HEIGHT.name],
      activeEnergyBurned: map[HealthDataType.ACTIVE_ENERGY_BURNED.name],
      basalEnergyBurned: map[HealthDataType.BASAL_ENERGY_BURNED.name],
      sleepAsleep: map[HealthDataType.SLEEP_ASLEEP.name],
      sleepAwake: map[HealthDataType.SLEEP_AWAKE.name],
      water: map[HealthDataType.WATER.name],
      bloodOxygen: map[HealthDataType.BLOOD_OXYGEN.name],
      flightsClimbed: (map[HealthDataType.FLIGHTS_CLIMBED.name] as double?)?.toInt(),
      distanceWalkingRunning: map[HealthDataType.DISTANCE_WALKING_RUNNING.name],
      bodyFatPercentage: map[HealthDataType.BODY_FAT_PERCENTAGE.name],
      bodyMassIndex: map[HealthDataType.BODY_MASS_INDEX.name],
      heartRateVariabilitySdnn: map[HealthDataType.HEART_RATE_VARIABILITY_SDNN.name],
      bloodPressureSystolic: map[HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name],
      bloodPressureDiastolic: map[HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name],
      bloodGlucose: map[HealthDataType.BLOOD_GLUCOSE.name],
      dietaryEnergyConsumed: map[HealthDataType.DIETARY_ENERGY_CONSUMED.name],
      restingHeartRate: map[HealthDataType.RESTING_HEART_RATE.name],
      // Custom aggregated values
      sleepDeep: map['sleepDeep'],
      sleepLight: map['sleepLight'],
      sleepRem: map['sleepRem'],
    );
  }

  @override
  @ignore
  List<Object?> get props => [
        source,
        steps,
        heartRate,
        weight,
        height,
        activeEnergyBurned,
        sleepAsleep,
        sleepAwake,
        water,
        bloodOxygen,
        basalEnergyBurned,
        flightsClimbed,
        distanceWalkingRunning,
        bodyFatPercentage,
        bodyMassIndex,
        heartRateVariabilitySdnn,
        bloodPressureSystolic,
        bloodPressureDiastolic,
        bloodGlucose,
        dietaryEnergyConsumed,
        sleepInBed,
        sleepDeep,
        sleepLight,
        sleepRem,
        restingHeartRate,
        caloriesBurned,
        timestamp
      ];

  @override
  @ignore
  bool? get stringify => true;
}
