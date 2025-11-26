import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Processes a raw list of health data records from Health Connect into a
/// structured summary map.
class MetricAggregator {
  /// Aggregates a list of raw health records.
  ///
  /// The [records] list is expected to contain `HealthDataPoint` objects from
  /// the `health` package.
  Map<String, dynamic> aggregateRecords(List<HealthDataPoint> records) {
    final aggregated = <String, dynamic>{
      HealthDataType.STEPS.name: 0.0,
      HealthDataType.ACTIVE_ENERGY_BURNED.name: 0.0,
      HealthDataType.FLIGHTS_CLIMBED.name: 0.0,
      HealthDataType.SLEEP_ASLEEP.name: 0.0,
      HealthDataType.SLEEP_AWAKE.name: 0.0,
      'sleepLight': 0.0, // Custom keys for sleep stages not in HealthDataType
      'sleepDeep': 0.0,
      'sleepRem': 0.0,
      HealthDataType.WATER.name: 0.0,
    };

    // Use a map to store the latest record for point-in-time metrics
    final latestRecords = <HealthDataType, HealthDataPoint>{};

    for (final record in records) {
      final recordType = record.type;
      final value = (record.value as NumericHealthValue).numericValue;

      // --- AGGREGATION LOGIC ---

      // 1. Summation for cumulative types
      switch (recordType) {
        case HealthDataType.STEPS:
        case HealthDataType.ACTIVE_ENERGY_BURNED:
        case HealthDataType.FLIGHTS_CLIMBED:
        case HealthDataType.WATER:
        case HealthDataType.SLEEP_ASLEEP:
        case HealthDataType.SLEEP_AWAKE:
          aggregated[recordType.name] = (aggregated[recordType.name] ?? 0.0) + value;
          break;
        // 2. Complex calculation for Sleep Stages (if available)
        // Note: The new API provides SLEEP_ASLEEP, SLEEP_AWAKE, etc directly.
        // If you were getting raw stage data, you would handle it here.
        // For now, we assume the direct values are sufficient.
        // Example for custom stage aggregation:
        // case HealthDataType.SLEEP_SESSION:
        //   if (record.value is SleepHealthValue) {
        //      final sleepValue = record.value as SleepHealthValue;
        //      // aggregate sleepValue.level
        //   }
        //   break;

        // 3. Store latest record for point-in-time metrics
        case HealthDataType.BASAL_ENERGY_BURNED:
        case HealthDataType.HEIGHT:
        case HealthDataType.WEIGHT:
        case HealthDataType.BODY_FAT_PERCENTAGE:
        case HealthDataType.BODY_TEMPERATURE:
        case HealthDataType.HEART_RATE:
        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        case HealthDataType.BLOOD_OXYGEN:
        case HealthDataType.BLOOD_GLUCOSE:
        case HealthDataType.RESPIRATORY_RATE:
        case HealthDataType.RESTING_HEART_RATE:
          final existingRecord = latestRecords[recordType];
          if (existingRecord == null || record.dateFrom.isAfter(existingRecord.dateFrom)) {
            latestRecords[recordType] = record;
          }
          break;
        default:
          // Other types not handled
          break;
      }
    }

    // --- FINALIZATION ---
    // Extract values from the latest records and populate aggregated map
    latestRecords.forEach((type, record) {
      aggregated[type.name] = (record.value as NumericHealthValue).numericValue;
    });

    // Note: The new API returns sleep data as total minutes for SLEEP_ASLEEP,
    // SLEEP_AWAKE, etc. The old logic for parsing stages is no longer needed
    // unless you fetch raw SLEEP_SESSION data. The current _types list fetches
    // the aggregated values directly.

    debugPrint('Aggregated Metrics: $aggregated');
    return aggregated;
  }
}