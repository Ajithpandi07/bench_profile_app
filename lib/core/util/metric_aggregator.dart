// lib/core/util/metric_aggregator.dart

import '../../features/health_metrics/domain/entities/health_metrics.dart';
import '../../features/health_metrics/domain/entities/health_metrics_summary.dart';
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
      final doubles = <String, double>{};
      final units = <String, String>{};

      // INIT
      doubles[HealthDataType.STEPS.name] = 0.0;
      units[HealthDataType.STEPS.name] = 'COUNT';

      doubles[HealthDataType.ACTIVE_ENERGY_BURNED.name] = 0.0;
      doubles[HealthDataType.FLIGHTS_CLIMBED.name] = 0.0;
      doubles[HealthDataType.SLEEP_ASLEEP.name] = 0.0;
      doubles[HealthDataType.SLEEP_AWAKE.name] = 0.0;
      doubles[HealthDataType.WATER.name] = 0.0;

      // Heart rate specific
      double hrSum = 0.0;
      int hrCount = 0;
      String hrUnit = 'BEATS_PER_MINUTE'; // default
      HealthMetrics? latestHrRecord;

      final latestRecords = <String, HealthMetrics>{};

      for (final record in records) {
        if (record == null) continue;
        final type = record.type ?? 'UNKNOWN';
        double val;
        try {
          val = record.value;
        } catch (_) {
          val = 0.0;
        }
        if (val.isNaN) val = 0.0;

        // Clean Unit
        String u = record.unit;
        // simplistic normalization
        if (u == 'NO_UNIT' || u == 'null') u = '';

        final isSummable = type == HealthDataType.STEPS.name ||
            type == HealthDataType.ACTIVE_ENERGY_BURNED.name ||
            type == HealthDataType.WATER.name ||
            type == HealthDataType.FLIGHTS_CLIMBED.name ||
            type == HealthDataType.SLEEP_ASLEEP.name ||
            type == HealthDataType.SLEEP_AWAKE.name;

        if (isSummable && val <= 0) continue;

        switch (type) {
          // Summable
          case var s when s == HealthDataType.STEPS.name:
          case var s when s == HealthDataType.ACTIVE_ENERGY_BURNED.name:
          case var s when s == HealthDataType.FLIGHTS_CLIMBED.name:
          case var s when s == HealthDataType.WATER.name:
          case var s when s == HealthDataType.SLEEP_ASLEEP.name:
          case var s when s == HealthDataType.SLEEP_AWAKE.name:
            doubles[type] = (doubles[type] ?? 0.0) + val;
            if (u.isNotEmpty) units[type] = u;
            break;

          // Heart Rate
          case var s when s == HealthDataType.HEART_RATE.name:
            hrSum += val;
            hrCount++;
            if (u.isNotEmpty) hrUnit = u;
            if (latestHrRecord == null ||
                record.dateFrom.isAfter(latestHrRecord.dateFrom)) {
              latestHrRecord = record;
            }
            break;

          // Latest
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
            final existing = latestRecords[type];
            if (existing == null ||
                record.dateFrom.isAfter(existing.dateFrom)) {
              latestRecords[type] = record;
            }
            break;

          default:
            final otherKey = 'other_$type';
            doubles[otherKey] = (doubles[otherKey] ?? 0.0) + val;
            if (u.isNotEmpty) units[otherKey] = u;
            break;
        }
      }

      final result = <String, dynamic>{};

      // Fill result with MetricValue objects
      // 1. Summables
      doubles.forEach((k, v) {
        // Round steps
        double finalVal = v;
        if (k == HealthDataType.STEPS.name) finalVal = v.roundToDouble();
        result[k] = MetricValue(finalVal, units[k] ?? '');
      });

      // 2. Heart Rate
      MetricValue? hrVal;
      if (useAverageHeartRate) {
        if (hrCount > 0) {
          hrVal = MetricValue(hrSum / hrCount, hrUnit);
        }
      } else {
        if (latestHrRecord != null) {
          hrVal = MetricValue(latestHrRecord.value, latestHrRecord.unit);
        }
      }
      if (hrVal != null) result[HealthDataType.HEART_RATE.name] = hrVal;

      // 3. Latest
      latestRecords.forEach((k, rec) {
        result[k] = MetricValue(rec.value, rec.unit);
      });

      debugPrint('Aggregated MetricValues: $result');
      return result;
    } catch (e, st) {
      debugPrint('MetricAggregator.aggregate FAILED: $e\n$st');
      return {};
    }
  }
}
