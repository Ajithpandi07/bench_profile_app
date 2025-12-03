import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/health_metrics.dart';
import '../repositories/health_repository.dart';

class GetHealthMetrics implements UseCase<HealthMetrics, NoParams> {
  final HealthRepository repository;
  GetHealthMetrics(this.repository);

  @override
  Future<Either<Failure, HealthMetrics>> call(NoParams params) {
    return repository.getHealthMetrics();
  }
}
