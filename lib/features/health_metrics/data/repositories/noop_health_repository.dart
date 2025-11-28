import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/health_metrics.dart';
import '../../domain/repositories/health_repository.dart';

/// Lightweight in-memory repository used when no real repository is provided.
/// Returns empty/default metrics and succeeds on saves. Useful for tests
/// and for ensuring `HealthBloc` is always available in the widget tree.
class NoopHealthRepository implements HealthRepository {
  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    final m = HealthMetrics(source: 'noop', steps: 0, heartRate: null, timestamp: DateTime.now());
    return Right(m);
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(DateTime start, DateTime end, List types) async {
    final m = HealthMetrics(source: 'noop', steps: 0, heartRate: null, timestamp: DateTime.now());
    return Right(m);
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid) async {
    return const Right(null);
  }
}
