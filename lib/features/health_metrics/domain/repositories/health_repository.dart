// lib/features/health_metrics/domain/repositories/health_repository.dart

import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import '../../../../core/error/failures.dart';
import '../entities/health_metrics.dart';

/// Repository interface for health metrics. Implementations live in data/.
abstract class HealthRepository {
  /// Returns latest health metrics from the device/platform (last 24h).
  /// Changed to return a list to keep the API consistent.
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics();

  /// Returns aggregated metrics for a specific date.
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(DateTime date);

  /// Returns aggregated metrics for a custom date range and data types.
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  );

  /// Persist health metrics for a user (e.g., upload to Firestore).
  Future<Either<Failure, void>> saveHealthMetrics(String uid, List<HealthMetrics> model);

  /// Returns the latest stored health metrics from the database for a user.
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(String uid);

  /// Triggers a background sync for health data for a given number of past days.
  Future<Either<Failure, void>> syncPastHealthData({int days = 30});
}
