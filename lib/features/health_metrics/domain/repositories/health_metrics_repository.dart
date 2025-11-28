// in features/health_metrics/domain/repositories/health_metrics_repository.dart

import 'package:bench_profile_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:health/health.dart';

import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';

abstract class HealthMetricsRepository {
  Future<Either<Failure, HealthMetrics>> getHealthMetrics();

    Future<Either<Failure, List<HealthMetrics>>> getMetricsForDate(DateTime date);


  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  );

  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model);
}
