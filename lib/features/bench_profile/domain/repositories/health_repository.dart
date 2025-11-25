import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import '../../../../core/error/failures.dart';
import '../entities/health_metrics.dart';

/// Repository interface for health metrics. Implementations live in data/.
abstract class HealthRepository {
  /// Returns latest health metrics from the device/platform (last 24h).
  Future<Either<Failure, HealthMetrics>> getHealthMetrics();

  /// Returns aggregated metrics for a custom date range and data types.
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(DateTime start, DateTime end, List<HealthDataType> types);

  /// Persist health metrics for a user (e.g., upload to Firestore). Accepts
  /// a domain `HealthMetrics` entity to avoid leaking data layer types.
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model);

  /// Returns the latest stored health metrics from the database for a user.
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid);
}
