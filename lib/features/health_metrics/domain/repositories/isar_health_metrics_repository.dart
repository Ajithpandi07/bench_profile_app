import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/health_metrics_data_source.dart';
import '../entities/health_metrics.dart';
import '../../domain/repositories/health_repository.dart';
import 'package:health/health.dart';

/// Simple repository-level failure wrapper (optional).
class RepositoryFailure extends Failure {
  RepositoryFailure(super.message);
}

/// Concrete Isar-backed implementation of HealthRepository.
class IsarHealthMetricsRepository implements HealthRepository {
  final Isar isar;
  final HealthMetricsDataSource healthDataSource;

  IsarHealthMetricsRepository({
    required this.isar,
    required this.healthDataSource,
  });

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() async {
    try {
      // Return metrics for today by default
      return getHealthMetricsForDate(DateTime.now());
    } catch (e) {
      return Left(RepositoryFailure('Failed to fetch latest health metrics: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      var query = isar.healthMetrics
          .filter()
          .dateFromGreaterThan(start, include: true)
          .dateFromLessThan(end, include: true);

      // Optional: filter by types if provided (method name depends on codegen)
      if (types.isNotEmpty) {
        final typeNames = types.map((t) => t.name).toList();
        // If Isar generated `typeIsIn` or similar, use it. Adjust if needed after codegen.
        // query = query.typeIsIn(typeNames);
      }

      final results = await query.sortByDateFrom().findAll();
      return Right(results);
    } catch (e) {
      return Left(RepositoryFailure('Failed to fetch health metrics range: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, List<HealthMetrics> models) async {
    try {
      await isar.writeTxn(() async {
        await isar.healthMetrics.putAll(models);
      });
      return const Right(null);
    } catch (e) {
      return Left(RepositoryFailure('Failed to save health metrics to local DB: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final results = await isar.healthMetrics
          .filter()
          .dateFromGreaterThan(start, include: true)
          .dateFromLessThan(end, include: false)
          .sortByDateFrom()
          .findAll();

      // Return an empty list when no results found (consumer can decide how to handle)
      return Right(results);
      // If we found metrics in the local DB, return them immediately.
      if (results.isNotEmpty) {
        return Right(results);
      }

      // If local DB is empty for this date, fetch from the device's health API.
      final deviceMetrics = await healthDataSource.getHealthMetricsForDate(date);

      // If we got new metrics from the device, save them to the local DB.
      if (deviceMetrics.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.healthMetrics.putAll(deviceMetrics);
        });
      }

      // Return the (potentially empty) list of metrics from the device.
      return Right(deviceMetrics);
    } catch (e) {
      return Left(RepositoryFailure('Failed to query metrics for date $date: $e'));
      return Left(RepositoryFailure('Failed to get metrics for date $date: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(String uid) async {
    // If you implement stored fetch from Firestore, replace this with real logic.
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 30}) async {
    try {
      final now = DateTime.now();
      final start = now.subtract(Duration(days: days));

      // For this implementation, we'll sync all available data types.
      // You could make this configurable if needed.
      final types = HealthDataType.values;

      // 1. Fetch all metrics from the device's Health API for the date range.
      final deviceMetrics = await healthDataSource.getHealthMetricsRange(start, now, types);

      if (deviceMetrics.isEmpty) {
        return const Right(null); // Nothing to do
      }

      // 2. Fetch existing metric UUIDs from the local database for the same range to avoid duplicates.
      final existingUuids = await isar.healthMetrics
          .filter()
          .dateFromBetween(start, now)
          .uuidProperty()
          .findAll();

      final existingUuidsSet = existingUuids.toSet();

      // 3. Filter out device metrics that are already in the local database.
      final newMetricsToSave = deviceMetrics.where((m) => !existingUuidsSet.contains(m.uuid)).toList();

      // 4. If there are new metrics, save them to the local Isar database.
      if (newMetricsToSave.isNotEmpty) {
        await isar.writeTxn(() async => await isar.healthMetrics.putAll(newMetricsToSave));
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(RepositoryFailure('Failed to sync past health data: $e'));
    }
  }
}
