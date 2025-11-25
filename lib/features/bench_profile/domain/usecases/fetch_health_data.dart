// lib/features/bench_profile/domain/usecases/fetch_health_data.dart
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/health_metrics.dart';
import '../repositories/health_repository.dart';

class FetchHealthData implements UseCase<HealthMetrics, NoParams> {
  final HealthRepository repository;

  FetchHealthData(this.repository);

  @override
  Future<Either<Failure, HealthMetrics>> call(NoParams params) async {
    return await repository.getHealthMetrics();
  }
}
