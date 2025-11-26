// lib/features/bench_profile/domain/entities/health_metrics.dart
import 'package:equatable/equatable.dart';

class HealthMetrics extends Equatable {
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
  final DateTime timestamp;

  const HealthMetrics({
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

  @override
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
}
