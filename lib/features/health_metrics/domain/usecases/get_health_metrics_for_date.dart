// lib/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart

import 'package:dartz/dartz.dart';
import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

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
