import 'package:equatable/equatable.dart';
import 'package:health/health.dart';

/// Represents an aggregated summary of health data for a single day.
/// This is a lightweight, non-persistent entity used for UI display.
class MetricValue extends Equatable {
  final double value;
  final String unit;

  const MetricValue(this.value, this.unit);

  @override
  List<Object?> get props => [value, unit];

  @override
  String toString() => '$value $unit';
}

/// Represents an aggregated summary of health data for a single day.
/// This is a lightweight, non-persistent entity used for UI display.
class HealthMetricsSummary extends Equatable {
  final DateTime timestamp;
  final String source;
  final MetricValue? steps;
  final MetricValue? heartRate;
  final MetricValue? weight;
  final MetricValue? height;
  final MetricValue? activeEnergyBurned;
  final MetricValue? sleepAsleep;
  final MetricValue? sleepAwake;
  final MetricValue? water;
  final MetricValue? bloodOxygen;
  final MetricValue? basalEnergyBurned;
  final MetricValue? flightsClimbed;
  final MetricValue? sleepDeep;
  final MetricValue? sleepLight;
  final MetricValue? sleepRem;
  final MetricValue? bodyFatPercentage;
  final MetricValue? bloodPressureSystolic;
  final MetricValue? bloodPressureDiastolic;
  final MetricValue? bodyTemperature;
  final MetricValue? bloodGlucose;

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
    this.bodyTemperature,
    this.bloodGlucose,
  });

  factory HealthMetricsSummary.fromMap(
      Map<String, dynamic> map, DateTime date) {
    // Helper to safely convert map value {value, unit} or just value to MetricValue?
    MetricValue? toMetric(dynamic data) {
      if (data == null) return null;
      if (data is MetricValue) return data;
      // If the aggregator put a Map here directly (unlikely but possible if JSON serialized)
      if (data is Map) {
        return MetricValue(
            (data['value'] as num).toDouble(), data['unit'] as String? ?? '');
      }
      // Fallback for raw numbers (legacy/testing support) - assume generic unit or empty
      if (data is num) {
        return MetricValue(data.toDouble(), '');
      }
      return null;
    }

    return HealthMetricsSummary(
      timestamp: date,
      source: map['source'] ?? 'health_package',
      steps: toMetric(map[HealthDataType.STEPS.name]),
      heartRate: toMetric(map[HealthDataType.HEART_RATE.name]),
      weight: toMetric(map[HealthDataType.WEIGHT.name]),
      height: toMetric(map[HealthDataType.HEIGHT.name]),
      activeEnergyBurned:
          toMetric(map[HealthDataType.ACTIVE_ENERGY_BURNED.name]),
      sleepAsleep: toMetric(map[HealthDataType.SLEEP_ASLEEP.name]),
      sleepAwake: toMetric(map[HealthDataType.SLEEP_AWAKE.name]),
      water: toMetric(map[HealthDataType.WATER.name]),
      bloodOxygen: toMetric(map[HealthDataType.BLOOD_OXYGEN.name]),
      basalEnergyBurned: toMetric(map[HealthDataType.BASAL_ENERGY_BURNED.name]),
      flightsClimbed: toMetric(map[HealthDataType.FLIGHTS_CLIMBED.name]),
      sleepDeep: toMetric(map['sleepDeep']),
      sleepLight: toMetric(map['sleepLight']),
      sleepRem: toMetric(map['sleepRem']),
      bodyFatPercentage: toMetric(map[HealthDataType.BODY_FAT_PERCENTAGE.name]),
      bloodPressureSystolic:
          toMetric(map[HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name]),
      bloodPressureDiastolic:
          toMetric(map[HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name]),
      bodyTemperature: toMetric(map[HealthDataType.BODY_TEMPERATURE.name]),
      bloodGlucose: toMetric(map[HealthDataType.BLOOD_GLUCOSE.name]),
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
        bodyTemperature,
        bloodGlucose,
      ];
}
