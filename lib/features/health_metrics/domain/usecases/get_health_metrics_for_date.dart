// lib/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/health_metrics.dart';
import '../repositories/health_repository.dart';

class DateParams {
  final DateTime date;
  DateParams(this.date);
}

class GetCachedMetricsForDate
    implements UseCase<List<HealthMetrics>, DateParams> {
  final HealthRepository repository;
  GetCachedMetricsForDate(this.repository);

  @override
  Future<Either<Failure, List<HealthMetrics>>> call(DateParams params) {
    return repository.getCachedMetricsForDate(params.date);
  }
}
