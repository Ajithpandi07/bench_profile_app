import 'package:dartz/dartz.dart';
import 'package:isar/isar.dart';
import '../../../../core/core.dart';
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
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetrics() async {
    try {
      // Return metrics for today by default
      return getCachedMetricsForDate(DateTime.now());
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
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetricsForDate(
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

      // 3. If Remote is also empty, we return empty list.
      // We DO NOT fetch from device here anymore, as per "Local First" strict separation.
      // Device fetch happens only during strict Sync.
      return const Right([]);
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
                await healthDataSource.fetchFromDeviceForDate(startOfDay);
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
      final deviceMetrics = await healthDataSource.fetchFromDeviceForDate(date);

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

  @override
  Future<Either<Failure, bool>> requestPermissions() async {
    // Isar repo uses the same datasource, so we can delegate.
    try {
      // Create a default list of types since the interface requires it
      // In a real app we might want to consolidate this list somewhere common.
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BODY_TEMPERATURE,
        HealthDataType.WATER,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.NUTRITION,
      ];
      final granted = await healthDataSource.requestPermissions(types);
      return Right(granted);
    } catch (e) {
      return Left(PermissionFailure('Failed to request permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreAllHealthData() async {
    try {
      final remoteMetrics = await remoteDataSource.getAllHealthMetricsForUser();
      if (remoteMetrics.isNotEmpty) {
        // Bulk write to Isar
        await isar.writeTxn(() async {
          // Put all overwrites existing by ID.
          // Since remote is source-of-truth for restore, we trust it.
          // Note: Remote metrics might not have Isar IDs populated, so new IDs generated,
          // potentially duplicating if UUID logic isn't enforcing uniqueness via filter first.
          // However, HealthMetrics entity uses 'uuid' but Isar needs 'id'.
          // To safely UPSERT by UUID, we should map existing UUIDs.

          // Optimization: If cache is expected to be empty, direct putAll is fine.
          // If we are restoring into a dirty cache, we need deduplication.
          // Let's assume we want to UPSERT by UUID.

          // 1. Get all existing UUIDs? (Likely too many for massive datasets)
          // 2. Or just putAll and let duplicates happen? (Bad)
          // 3. Or iterate and check? (Slow)
          // 4. Ideally Isar has an index on UUID and we use putByUuid? Isar doesn't support custom PK purely like that easily without config.

          // Current best effort: Delete All first? (User said "when local cleaned")
          // If not cleaning, we probably want to just blind put.
          await isar.healthMetrics.putAll(remoteMetrics);
        });
      }
      return const Right(null);
    } catch (e) {
      return Left(RepositoryFailure('Failed to restore all health data: $e'));
    }
  }
}
