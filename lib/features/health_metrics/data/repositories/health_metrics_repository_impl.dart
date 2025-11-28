// health_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_metrics_repository.dart';
import 'package:health/health.dart';

import '../models/health_metrics_model.dart';

class HealthMetricsRepositoryImpl implements HealthMetricsRepository {
  final HealthMetricsLocalDataSource localDataSource;

  HealthMetricsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    try {
      final HealthMetricsModel model = await localDataSource.fetchHealthData();
      return Right(model);
    } on Exception catch (e, st) {
      return Left(Failure('Failed to fetch health data: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      final HealthMetricsModel model =
          await localDataSource.fetchHealthDataRange(start, end, types);
      // return list containing model (or return Right([]) if you want empty semantics)
      return Right([model]);
    } on Exception catch (e) {
      return Left(Failure('Failed to fetch range health data: ${e.toString()}'));
    }
  }

  /// Fetch daily metrics for [date]. Returns Right(list) on success (can be empty),
  /// or Left(Failure) on error.
  @override
  Future<Either<Failure, List<HealthMetrics>>> getMetricsForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    try {
      // Choose default types to fetch — adjust as needed.
      final List<HealthDataType> types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
      ];

      // localDataSource.fetchHealthDataRange expected to return a model for the range.
      // If your datasource returns a list, adapt this block accordingly.
      final HealthMetricsModel model =
          await localDataSource.fetchHealthDataRange(start, end, types);

      // If datasource returns a model but there is no data inside it, you can return Right([]).
      // Here we treat the model as one result; if you want to aggregate across many entries,
      // change localDataSource to return List<HealthMetricsModel>.
      if (model == null) {
        // defensive — though model is probably non-nullable; keep fallback
        return Right(<HealthMetrics>[]);
      }

      return Right(<HealthMetrics>[model]);
    } on Exception catch (e) {
      return Left(Failure('Failed to fetch health metrics for date: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    try {
      final HealthMetricsModel toSave;
      if (model is HealthMetricsModel) {
        toSave = model;
      } else {
        // Map entity -> model. Provide null-safe defaults if fields are nullable.
        toSave = HealthMetricsModel(
          source: (model as dynamic).source ?? 'unknown',
          timestamp: (model as dynamic).timestamp ?? DateTime.now(),
          steps: (model as dynamic).steps ?? 0,
          heartRate: (model as dynamic).heartRate,
          weight: (model as dynamic).weight,
          height: (model as dynamic).height,
          activeEnergyBurned: (model as dynamic).activeEnergyBurned,
          sleepAsleep: (model as dynamic).sleepAsleep,
          sleepAwake: (model as dynamic).sleepAwake,
          water: (model as dynamic).water,
          bloodOxygen: (model as dynamic).bloodOxygen,
          basalEnergyBurned: (model as dynamic).basalEnergyBurned,
          flightsClimbed: (model as dynamic).flightsClimbed,
          distanceWalkingRunning: (model as dynamic).distanceWalkingRunning,
          bodyFatPercentage: (model as dynamic).bodyFatPercentage,
          bodyMassIndex: (model as dynamic).bodyMassIndex,
          heartRateVariabilitySdnn: (model as dynamic).heartRateVariabilitySdnn,
          bloodPressureSystolic: (model as dynamic).bloodPressureSystolic,
          bloodPressureDiastolic: (model as dynamic).bloodPressureDiastolic,
          bloodGlucose: (model as dynamic).bloodGlucose,
          dietaryEnergyConsumed: (model as dynamic).dietaryEnergyConsumed,
          sleepInBed: (model as dynamic).sleepInBed,
          sleepDeep: (model as dynamic).sleepDeep,
          sleepLight: (model as dynamic).sleepLight,
          sleepRem: (model as dynamic).sleepRem,
          restingHeartRate: (model as dynamic).restingHeartRate,
          caloriesBurned: (model as dynamic).caloriesBurned,
        );
      }

      await localDataSource.saveHealthMetricsToFirestore(uid, toSave);
      return const Right(null);
    } on Exception catch (e) {
      return Left(Failure('Failed to save health metrics: ${e.toString()}'));
    }
  }
}
