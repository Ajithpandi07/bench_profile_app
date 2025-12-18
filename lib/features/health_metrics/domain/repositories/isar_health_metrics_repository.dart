import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../core/error/failures.dart';
import '../../data/datasources/health_metrics_data_source.dart';
import '../../data/datasources/remote/health_metrics_remote_data_source.dart';
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
  final HealthMetricsRemoteDataSource remoteDataSource;

  IsarHealthMetricsRepository({
    required this.isar,
    required this.healthDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() async {
    try {
      // Return metrics for today by default
      return getHealthMetricsForDate(DateTime.now());
    } catch (e) {
      return Left(
          RepositoryFailure('Failed to fetch latest health metrics: $e'));
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
      return Left(
          RepositoryFailure('Failed to fetch health metrics range: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(
      String uid, List<HealthMetrics> models) async {
    try {
      await isar.writeTxn(() async {
        await isar.healthMetrics.putAll(models);
      });
      return const Right(null);
    } catch (e) {
      return Left(
          RepositoryFailure('Failed to save health metrics to local DB: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(
      DateTime date) async {
    try {
      // Trigger sync if fetching for today (app opening scenario)
      final now = DateTime.now();
      // if (date.year == now.year && date.month == now.month && date.day == now.day) {
      //   await syncPastHealthData();
      // }

      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));

      final results = await isar.healthMetrics
          .filter()
          .dateFromGreaterThan(start, include: true)
          .dateFromLessThan(end, include: false)
          .sortByDateFrom()
          .findAll();

      // If we found metrics in the local DB, return them immediately.
      if (results.isNotEmpty) {
        return Right(results);
      }

      // 2. If local DB is empty, try fetching from Remote (Firestore).
      try {
        final remoteMetrics =
            await remoteDataSource.getHealthMetricsForDate(date);
        if (remoteMetrics.isNotEmpty) {
          // Save remote data to local DB for next time
          await isar.writeTxn(() async {
            await isar.healthMetrics.putAll(remoteMetrics);
          });
          return Right(remoteMetrics);
        }
      } catch (e) {
        // Ignore remote errors and proceed to device fetch
      }

      // 3. If Remote is also empty/failed, fetch from the device's health API.
      final deviceMetrics =
          await healthDataSource.getHealthMetricsForDate(date);

      if (deviceMetrics.isNotEmpty) {
        await isar.writeTxn(() async {
          await isar.healthMetrics.putAll(deviceMetrics);
        });
      }

      // Return the (potentially empty) list of metrics from the device.
      return Right(deviceMetrics);
    } catch (e) {
      return Left(
          RepositoryFailure('Failed to query metrics for date $date: $e'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(
      String uid) async {
    // If you implement stored fetch from Firestore, replace this with real logic.
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 30}) async {
    try {
      final now = DateTime.now();

      // Iterate through each day to check data availability individually
      for (int i = 0; i <= days; i++) {
        final date = now.subtract(Duration(days: i));
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));

        // Check if we have data in local DB for this specific day
        final localCount = await isar.healthMetrics
            .filter()
            .dateFromGreaterThan(startOfDay, include: true)
            .dateFromLessThan(endOfDay, include: false)
            .count();

        if (localCount == 0) {
          // Case 1: No local data -> Sync from REMOTE only (Restore)
          try {
            final remoteMetrics =
                await remoteDataSource.getHealthMetricsForDate(startOfDay);
            if (remoteMetrics.isNotEmpty) {
              await isar.writeTxn(
                  () async => await isar.healthMetrics.putAll(remoteMetrics));
            }
          } catch (_) {}
        } else {
          // Case 2: Local data exists -> Sync from DEVICE (Update)
          // We fetch from device to ensure we have the latest data for this day
          try {
            final deviceMetrics =
                await healthDataSource.getHealthMetricsForDate(startOfDay);
            if (deviceMetrics.isNotEmpty) {
              // Deduplicate: Get existing UUIDs for this day
              final existingUuids = await isar.healthMetrics
                  .filter()
                  .dateFromGreaterThan(startOfDay, include: true)
                  .dateFromLessThan(endOfDay, include: false)
                  .uuidProperty()
                  .findAll();

              final existingSet = existingUuids.toSet();
              final newMetrics = deviceMetrics
                  .where((m) => !existingSet.contains(m.uuid))
                  .toList();

              if (newMetrics.isNotEmpty) {
                await isar.writeTxn(
                    () async => await isar.healthMetrics.putAll(newMetrics));
              }
            }
          } catch (_) {}
        }
      }

      return const Right(null);
    } on Exception catch (e) {
      return Left(RepositoryFailure('Failed to sync past health data: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> syncMetricsForDate(DateTime date) async {
    try {
      // 1. Fetch from Device
      final deviceMetrics =
          await healthDataSource.getHealthMetricsForDate(date);

      // 2. Upload to Remote (Device -> Remote)
      if (deviceMetrics.isNotEmpty) {
        try {
          await remoteDataSource.uploadHealthMetrics(deviceMetrics);
        } catch (_) {
          // Continue even if upload fails
        }
      }

      // 3. Fetch from Remote to get merged data (Remote -> Client)
      List<HealthMetrics> finalMetrics = deviceMetrics;
      try {
        final remoteMetrics =
            await remoteDataSource.getHealthMetricsForDate(date);
        if (remoteMetrics.isNotEmpty) {
          finalMetrics = remoteMetrics;
        }
      } catch (_) {
        // Fallback to device metrics
      }

      // 4. Save to Local (Client -> Local)
      if (finalMetrics.isNotEmpty) {
        // Fetch existing UUIDs and IDs for this date to support UPSERT
        final start = DateTime(date.year, date.month, date.day);
        final end = start.add(const Duration(days: 1));

        final existingItems = await isar.healthMetrics
            .filter()
            .dateFromGreaterThan(start, include: true)
            .dateFromLessThan(end, include: false)
            .findAll();

        final uuidToIdMap = {for (var i in existingItems) i.uuid: i.id};

        // Assign existing Isar IDs to incoming metrics ensuring updates instead of duplicates
        final metricsToSave = finalMetrics.map((m) {
          if (uuidToIdMap.containsKey(m.uuid)) {
            m.id = uuidToIdMap[m.uuid]!;
          }
          return m;
        }).toList();

        await isar.writeTxn(() async {
          await isar.healthMetrics.putAll(metricsToSave);
        });
      }

      return const Right(null);
    } catch (e) {
      return Left(
          RepositoryFailure('Failed to sync metrics for date $date: $e'));
    }
  }
}
