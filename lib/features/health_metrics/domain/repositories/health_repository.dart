// lib/features/health_metrics/domain/repositories/health_repository.dart

import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import '../../../../core/core.dart';
import '../entities/health_metrics.dart';

/// Repository interface for health metrics. Implementations live in data/.
abstract class HealthRepository {
  /// Returns latest health metrics from the device/platform (last 24h).
  /// Changed to return a list to keep the API consistent.
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetrics();

  /// Returns aggregated metrics for a specific date from CACHE (Local DB).
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetricsForDate(
      DateTime date);

  /// Returns aggregated metrics for a custom date range and data types.
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  );

  /// Persist health metrics for a user (e.g., upload to Firestore).
  Future<Either<Failure, void>> saveHealthMetrics(
      String uid, List<HealthMetrics> model);

  /// Returns the latest stored health metrics from the database for a user.
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(
      String uid);

  /// Triggers a background sync for health data for a given number of past days.
  Future<Either<Failure, void>> syncPastHealthData({int days = 1});

  /// Explicitly syncs data for a specific date (Device -> Remote -> Local).
  Future<Either<Failure, void>> syncMetricsForDate(DateTime date);

  /// Requests health permissions from the user. Returns true if granted.
  Future<Either<Failure, bool>> requestPermissions();

  /// Restores ALL historical data from Remote to Local (e.g. fresh install or cache clear).
  Future<Either<Failure, void>> restoreAllHealthData();
}
