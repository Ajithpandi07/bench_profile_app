import 'package:equatable/equatable.dart';
import 'package:health/health.dart';

/// Represents an aggregated summary of health data for a single day.
/// This is a lightweight, non-persistent entity used for UI display.
class HealthMetricsSummary extends Equatable {
  final DateTime timestamp;
  final String source;
  final double? steps;
  final double? heartRate;
  final double? weight;
  final double? height;
  final double? activeEnergyBurned;
  final double? sleepAsleep;
  final double? sleepAwake;
  final double? water;
  final double? bloodOxygen;
  final double? basalEnergyBurned;
  final double? flightsClimbed;
  final double? sleepDeep;
  final double? sleepLight;
  final double? sleepRem;
  final double? bodyFatPercentage;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;

  const HealthMetricsSummary({
    required this.timestamp,
    required this.source,
    this.steps,
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
    this.sleepDeep,
    this.sleepLight,
    this.sleepRem,
    this.bodyFatPercentage,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
  });

  factory HealthMetricsSummary.fromMap(Map<String, dynamic> map, DateTime date) {
    // Helper to safely convert int/double/num to double?
    double? toDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return null;
    }

    return HealthMetricsSummary(
      timestamp: date,
      source: map['source'] ?? 'health_package',
      steps: toDouble(map[HealthDataType.STEPS.name]),
      heartRate: toDouble(map[HealthDataType.HEART_RATE.name]),
      weight: toDouble(map[HealthDataType.WEIGHT.name]),
      height: toDouble(map[HealthDataType.HEIGHT.name]),
      activeEnergyBurned: toDouble(map[HealthDataType.ACTIVE_ENERGY_BURNED.name]),
      sleepAsleep: toDouble(map[HealthDataType.SLEEP_ASLEEP.name]),
      sleepAwake: toDouble(map[HealthDataType.SLEEP_AWAKE.name]),
      water: toDouble(map[HealthDataType.WATER.name]),
      bloodOxygen: toDouble(map[HealthDataType.BLOOD_OXYGEN.name]),
      basalEnergyBurned: toDouble(map[HealthDataType.BASAL_ENERGY_BURNED.name]),
      flightsClimbed: toDouble(map[HealthDataType.FLIGHTS_CLIMBED.name]),
      sleepDeep: toDouble(map['sleepDeep']),
      sleepLight: toDouble(map['sleepLight']),
      sleepRem: toDouble(map['sleepRem']),
      bodyFatPercentage: toDouble(map[HealthDataType.BODY_FAT_PERCENTAGE.name]),
      bloodPressureSystolic: toDouble(map[HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name]),
      bloodPressureDiastolic: toDouble(map[HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name]),
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
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
        sleepDeep,
        sleepLight,
        sleepRem,
        bodyFatPercentage,
        bloodPressureSystolic,
        bloodPressureDiastolic,
      ];
}