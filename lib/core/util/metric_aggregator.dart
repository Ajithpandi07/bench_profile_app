import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// Processes a raw list of health data records from Health Connect into a
/// structured summary map.
class MetricAggregator {
  /// Aggregates a list of HealthMetrics entities into a summary map.
  ///
  /// The [records] list is expected to contain `HealthMetrics` domain entities.
  Map<String, dynamic> aggregate(List<HealthMetrics> records) {
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
    final latestRecords = <String, HealthMetrics>{};

    for (final record in records) {
      final recordTypeString = record.type;
      final value = record.value;

      // --- AGGREGATION LOGIC ---

      // 1. Summation for cumulative types
      switch (recordTypeString) {
        case 'STEPS':
        case 'ACTIVE_ENERGY_BURNED':
        case 'FLIGHTS_CLIMBED':
        case 'WATER':
        case 'SLEEP_ASLEEP':
        case 'SLEEP_AWAKE':
          aggregated[recordTypeString] = (aggregated[recordTypeString] ?? 0.0) + value;
          break;
        // 2. Complex calculation for Sleep Stages (if available)
        // Note: The new API provides SLEEP_ASLEEP, SLEEP_AWAKE, etc directly.
        // If you were getting raw stage data, you would handle it here.
        // For now, we assume the direct values are sufficient.

        // 3. Store latest record for point-in-time metrics
        case 'BASAL_ENERGY_BURNED':
        case 'HEIGHT':
        case 'WEIGHT':
        case 'BODY_FAT_PERCENTAGE':
        case 'BODY_TEMPERATURE':
        case 'HEART_RATE':
        case 'BLOOD_PRESSURE_SYSTOLIC':
        case 'BLOOD_PRESSURE_DIASTOLIC':
        case 'BLOOD_OXYGEN':
        case 'BLOOD_GLUCOSE':
        case 'RESPIRATORY_RATE':
        case 'RESTING_HEART_RATE':
          final existingRecord = latestRecords[recordTypeString];
          if (existingRecord == null || record.dateFrom.isAfter(existingRecord.dateFrom)) {
            latestRecords[recordTypeString] = record;
          }
          break;
        default:
          // Other types not handled
          break;
      }
    }

    // --- FINALIZATION ---
    // Extract values from the latest records and populate aggregated map
    latestRecords.forEach((typeString, record) {
      aggregated[typeString] = record.value;
    });

    // Note: The new API returns sleep data as total minutes for SLEEP_ASLEEP,
    // SLEEP_AWAKE, etc. The old logic for parsing stages is no longer needed
    // unless you fetch raw SLEEP_SESSION data. The current _types list fetches
    // the aggregated values directly.

    debugPrint('Aggregated Metrics: $aggregated');
    return aggregated;
  }
}