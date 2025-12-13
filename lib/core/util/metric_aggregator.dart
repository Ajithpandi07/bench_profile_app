// lib/core/util/metric_aggregator.dart

import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// MetricAggregator that computes both average and latest heart rate.
/// `useAverageHeartRate` selects which value is placed at the canonical
/// `HealthDataType.HEART_RATE.name` key for backward compatibility.
class MetricAggregator {
  final bool useAverageHeartRate;

  MetricAggregator({bool? useAverageHeartRate})
      : useAverageHeartRate = useAverageHeartRate ?? false;

  Map<String, dynamic> aggregate(List<HealthMetrics> records) {
    try {
      final aggregated = <String, dynamic>{
        HealthDataType.STEPS.name: 0.0,
        HealthDataType.ACTIVE_ENERGY_BURNED.name: 0.0,
        HealthDataType.FLIGHTS_CLIMBED.name: 0.0,
        HealthDataType.SLEEP_ASLEEP.name: 0.0,
        HealthDataType.SLEEP_AWAKE.name: 0.0,
        'sleepLight': 0.0,
        'sleepDeep': 0.0,
        'sleepRem': 0.0,
        HealthDataType.WATER.name: 0.0,
        // We'll add explicit keys for heart rate summary
        'heartRateAverage': null,
        'heartRateLatest': null,
        // canonical HEART_RATE will be set later to one of the above
        HealthDataType.HEART_RATE.name: null,
        HealthDataType.WEIGHT.name: null,
        HealthDataType.HEIGHT.name: null,
      };

      // heart rate accumulators
      double hrSum = 0.0;
      int hrCount = 0;
      HealthMetrics? latestHrRecord;

      final latestRecords = <String, HealthMetrics>{};

      for (final record in records) {
        if (record == null) continue;

        final recordTypeString = record.type ?? 'UNKNOWN';
        double value;
        try {
          value = record.value;
        } catch (_) {
          value = 0.0;
        }
        if (value.isNaN) value = 0.0;

        final isSummable = recordTypeString == HealthDataType.STEPS.name ||
            recordTypeString == HealthDataType.ACTIVE_ENERGY_BURNED.name ||
            recordTypeString == HealthDataType.WATER.name ||
            recordTypeString == HealthDataType.FLIGHTS_CLIMBED.name ||
            recordTypeString == HealthDataType.SLEEP_ASLEEP.name ||
            recordTypeString == HealthDataType.SLEEP_AWAKE.name;

        if (isSummable && value <= 0) continue;

        switch (recordTypeString) {
          // Summable types
          case var s when s == HealthDataType.STEPS.name:
          case var s when s == HealthDataType.ACTIVE_ENERGY_BURNED.name:
          case var s when s == HealthDataType.FLIGHTS_CLIMBED.name:
          case var s when s == HealthDataType.WATER.name:
          case var s when s == HealthDataType.SLEEP_ASLEEP.name:
          case var s when s == HealthDataType.SLEEP_AWAKE.name:
            aggregated[recordTypeString] = (aggregated[recordTypeString] ?? 0.0) + value;
            break;

          // Heart rate: collect for average and latest
          case var s when s == HealthDataType.HEART_RATE.name:
            // accumulate for average
            hrSum += value;
            hrCount += 1;
            // track latest
            if (latestHrRecord == null || record.dateFrom.isAfter(latestHrRecord.dateFrom)) {
              latestHrRecord = record;
            }
            break;

          // Point-in-time: keep latest
          case var s when s == HealthDataType.BASAL_ENERGY_BURNED.name:
          case var s when s == HealthDataType.HEIGHT.name:
          case var s when s == HealthDataType.WEIGHT.name:
          case var s when s == HealthDataType.BODY_FAT_PERCENTAGE.name:
          case var s when s == HealthDataType.BODY_TEMPERATURE.name:
          case var s when s == HealthDataType.BLOOD_PRESSURE_SYSTOLIC.name:
          case var s when s == HealthDataType.BLOOD_PRESSURE_DIASTOLIC.name:
          case var s when s == HealthDataType.BLOOD_OXYGEN.name:
          case var s when s == HealthDataType.BLOOD_GLUCOSE.name:
          case var s when s == HealthDataType.RESPIRATORY_RATE.name:
          case var s when s == HealthDataType.RESTING_HEART_RATE.name:
            final existingRecord = latestRecords[recordTypeString];
            if (existingRecord == null || record.dateFrom.isAfter(existingRecord.dateFrom)) {
              latestRecords[recordTypeString] = record;
            }
            break;

          default:
            // Collect under other_<type> so nothing is lost
            final otherKey = 'other_${recordTypeString}';
            final prev = aggregated[otherKey] ?? 0.0;
            aggregated[otherKey] = (prev is num ? prev.toDouble() : 0.0) + value;
            break;
        }
      }

      // finalize heart rate values
      if (hrCount > 0) {
        aggregated['heartRateAverage'] = hrSum / hrCount;
      } else {
        aggregated['heartRateAverage'] = null;
      }

      aggregated['heartRateLatest'] = latestHrRecord?.value;

      // set canonical HEART_RATE key according to flag for backward compatibility
      aggregated[HealthDataType.HEART_RATE.name] =
          useAverageHeartRate ? aggregated['heartRateAverage'] : aggregated['heartRateLatest'];

      // inject latest point-in-time values
      latestRecords.forEach((typeString, record) {
        try {
          aggregated[typeString] = record.value;
        } catch (_) {
          aggregated[typeString] = null;
        }
      });

      // friendly conversion: make steps integer
      final stepsVal = aggregated[HealthDataType.STEPS.name];
      if (stepsVal is num) {
        aggregated[HealthDataType.STEPS.name] = (stepsVal).round();
      }

      debugPrint('Aggregated Metrics: $aggregated');
      return aggregated;
    } catch (e, st) {
      debugPrint('MetricAggregator.aggregate FAILED: $e\n$st');
      return <String, dynamic>{
        HealthDataType.STEPS.name: 0,
        'heartRateAverage': null,
        'heartRateLatest': null,
      };
    }
  }
}
