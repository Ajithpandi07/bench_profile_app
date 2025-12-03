// lib/features/health_metrics/data/repositories/isar_health_metrics_repository.dart

import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/health_metrics.dart';
import '../../domain/repositories/health_repository.dart';
import 'package:health/health.dart';

/// Simple repository-level failure wrapper. Replace with your app-specific
/// Failure subclasses (e.g., CacheFailure) if you have them.
class RepositoryFailure extends Failure {
  RepositoryFailure(super.message);
}

/// Concrete Isar-backed implementation of HealthMetricsRepository.
class IsarHealthMetricsRepository implements HealthRepository {
  final Isar isar;

  IsarHealthMetricsRepository({required this.isar});

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    try {
      // Return most-recent metrics (by timestamp) if any
      final list = await isar.healthMetrics.where().sortByTimestampDesc().limit(1).findAll();
      if (list.isEmpty) {
        return Left(RepositoryFailure('No health metrics found'));
      }
      return Right(list.first);
    } catch (e) {
      return Left(RepositoryFailure('Failed to fetch latest health metrics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getMetricsForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final results = await isar.healthMetrics
          .filter()
          .timestampGreaterThan(start, include: true)
          .timestampLessThan(end, include: false)
          .sortByTimestamp()
          .findAll();

      return Right(results);
    } catch (e) {
      return Left(RepositoryFailure('Failed to query metrics for date $date: $e'));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      // Since HealthMetrics stores aggregated fields, `types` can't be used to filter
      // Isar results unless you store per-type rows. We just return aggregated records
      // between start and end.
      final result = await isar.healthMetrics
          .filter()
          .timestampGreaterThan(start, include: true)
          .timestampLessThan(end, include: true)
          .sortByTimestamp()
          .findFirst();

      return Right(result!);
    } catch (e) {
      return Left(RepositoryFailure('Failed to fetch health metrics range: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    try {
      await isar.writeTxn(() async {
        // Your entity doesn't currently have a uid field — if you need multi-user
        // support add `String uid` to HealthMetrics and use it here.
        await isar.healthMetrics.put(model);
      });
      return const Right(null);
    } catch (e) {
      return Left(RepositoryFailure('Failed to save health metrics: $e'));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final result = await isar.healthMetrics.filter().timestampBetween(start, end).findFirst();
      if (result == null) return Left(RepositoryFailure('No metrics found for date'));
      return Right(result);
    } catch (e) {
      return Left(RepositoryFailure('Failed to get metrics by date'));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid) async =>
      const Right(null);
}
