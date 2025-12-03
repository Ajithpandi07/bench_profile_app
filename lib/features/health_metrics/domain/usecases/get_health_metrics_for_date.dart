import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/core/usecase/usecase.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';

class GetHealthMetricsForDate implements UseCase<HealthMetrics, DateParams> {
  final HealthRepository repository;

  GetHealthMetricsForDate(this.repository);

  @override
  Future<Either<Failure, HealthMetrics>> call(DateParams params) async {
    // If your repository returns List<HealthMetrics>, fetch list and aggregate here
    final either = await repository.getMetricsForDate(params.date);

    return either.fold(
      (failure) => Left(failure),
      (List<HealthMetrics> list) {
        if (list.isEmpty) {
          // return an empty / zeroed HealthMetrics entity (adjust according to your entity ctor)
          final empty = HealthMetrics(source: 'error',timestamp: params.date, steps: 0);
          return Right(empty);
        } else {
          // Aggregate list into a single HealthMetrics (implement your own aggregation logic if needed)
          final aggregated = _aggregateDailyMetrics(list);
          return Right(aggregated);
        }
      },
    );
  }

  HealthMetrics _aggregateDailyMetrics(List<HealthMetrics> list) {
    final steps = list.fold<int>(0, (prev, e) => prev + (e.steps));
    final hrPoints = list.map((m) => m.heartRate).where((v) => v != null).map((v) => v!).toList();
    final avgHr = hrPoints.isEmpty ? null : hrPoints.reduce((a, b) => a + b) / hrPoints.length;
    final weight = list.map((m) => m.weight).firstWhere((w) => w != null, orElse: () => null);
    return HealthMetrics(
      source: list.map((m) => m.source).firstWhere((s) => s != null, orElse: () => ''),
      steps: steps,
      heartRate: avgHr,
      weight: weight,
      height: list.map((m) => m.height).firstWhere((h) => h != null, orElse: () => null),
      activeEnergyBurned: list.map((m) => m.activeEnergyBurned ?? 0).fold<double>(0.0, (p, n) => p + n),
      timestamp: list.map((m) => m.timestamp).firstWhere((t) => t != null, orElse: () => DateTime.now()),
    );
  }
}
