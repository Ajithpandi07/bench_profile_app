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
    return HealthMetricsSummary(
      timestamp: date,
      source: map['source'] ?? 'health_package',
      steps: map[HealthDataType.STEPS.name],
      heartRate: map[HealthDataType.HEART_RATE.name],
      weight: map[HealthDataType.WEIGHT.name],
      height: map[HealthDataType.HEIGHT.name],
      activeEnergyBurned: map[HealthDataType.ACTIVE_ENERGY_BURNED.name],
      sleepAsleep: map[HealthDataType.SLEEP_ASLEEP.name],
      sleepAwake: map[HealthDataType.SLEEP_AWAKE.name],
      water: map[HealthDataType.WATER.name],
      bloodOxygen: map[HealthDataType.BLOOD_OXYGEN.name],
      basalEnergyBurned: map[HealthDataType.BASAL_ENERGY_BURNED.name],
      flightsClimbed: map[HealthDataType.FLIGHTS_CLIMBED.name],
      sleepDeep: map['sleepDeep'],
      sleepLight: map['sleepLight'],
      sleepRem: map['sleepRem'],
      bodyFatPercentage: map[HealthDataType.BODY_FAT_PERCENTAGE.name],
      bloodPressureSystolic: map[HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name],
      bloodPressureDiastolic: map[HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name],
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