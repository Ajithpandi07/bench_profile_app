// lib/features/health_metrics/domain/usecases/get_health_metrics.dart

import 'package:dartz/dartz.dart';
import '../../../../core/core.dart';
import '../entities/entities.dart';
import '../repositories/repositories.dart';

class GetCachedMetrics implements UseCase<List<HealthMetrics>, NoParams> {
  final HealthRepository repository;
  GetCachedMetrics(this.repository);

  @override
  Future<Either<Failure, List<HealthMetrics>>> call(NoParams params) {
    return repository.getCachedMetrics();
  }
}
