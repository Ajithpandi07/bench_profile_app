// lib/features/health_metrics/domain/usecases/get_health_metrics.dart

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/health_metrics.dart';
import '../repositories/health_repository.dart';

class GetHealthMetrics implements UseCase<List<HealthMetrics>, NoParams> {
  final HealthRepository repository;
  GetHealthMetrics(this.repository);

  @override
  Future<Either<Failure, List<HealthMetrics>>> call(NoParams params) {
    return repository.getHealthMetrics();
  }
}
