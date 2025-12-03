import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

/// A centralized list of all the health data types the app requests.
const requestedHealthTypes = [
  HealthDataType.STEPS,
  HealthDataType.HEART_RATE,
  HealthDataType.WEIGHT,
  HealthDataType.HEIGHT,
  HealthDataType.ACTIVE_ENERGY_BURNED,
  HealthDataType.BASAL_ENERGY_BURNED,
  HealthDataType.SLEEP_ASLEEP,
  HealthDataType.SLEEP_AWAKE,
  HealthDataType.WATER,
  HealthDataType.BLOOD_OXYGEN,
  HealthDataType.FLIGHTS_CLIMBED,
  HealthDataType.DISTANCE_WALKING_RUNNING,
  HealthDataType.BODY_FAT_PERCENTAGE,
  HealthDataType.BODY_MASS_INDEX,
  HealthDataType.HEART_RATE_VARIABILITY_SDNN,
  HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
  HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  HealthDataType.BLOOD_GLUCOSE,
  HealthDataType.DIETARY_ENERGY_CONSUMED,
  HealthDataType.RESTING_HEART_RATE,
];

class HealthMetricsDataSourceImpl implements HealthMetricsDataSource {
  final Health health;
  final MetricAggregator aggregator;

  HealthMetricsDataSourceImpl({
    required this.health,
    required this.aggregator,
  });

  @override
  Future<HealthMetrics> getHealthMetricsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    try {
      // Request authorization for the data types.
      final permissions = requestedHealthTypes.map((e) => HealthDataAccess.READ).toList();
      bool requested = await health.requestAuthorization(requestedHealthTypes, permissions: permissions);

      if (!requested) {
        debugPrint('Authorization not granted for health data types.');
        throw PermissionDeniedException();
      }

      // Fetch health data.
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: startOfDay,
        endTime: endOfDay,
        types: requestedHealthTypes,
      );

      // Delegate the complex aggregation logic to the injected aggregator.
      final aggregatedData = aggregator.aggregateRecords(healthData);

      // Use the new factory constructor to create the entity.
      return HealthMetrics.fromAggregatedMap(aggregatedData, date);
    } on PermissionDeniedException {
      rethrow; // Allow the specific permission exception to pass through.
    } catch (e, stackTrace) {
      // Log the original error and stack trace for better debugging.
      debugPrint('Failed to fetch health data: $e');
      debugPrint(stackTrace.toString());
      // Throw a generic but informative exception for the repository to handle.
      throw ServerException();
    }
  }
}