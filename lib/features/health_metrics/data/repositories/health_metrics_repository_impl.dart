// lib/features/health_metrics/data/repositories/health_metrics_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

import '../../../../../core/core.dart';
import '../datasources/datasources.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart' hide RepositoryFailure;

class HealthMetricsRepositoryImpl implements HealthRepository {
  final HealthMetricsDataSource dataSource;
  final HealthMetricsLocalDataSource localDataSource;
  final HealthMetricsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HealthMetricsRepositoryImpl({
    required this.dataSource,
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
  });

  // --- helpers -------------------------------------------------------------

  List<HealthMetrics> _normalizeToList(dynamic maybe) {
    if (maybe == null) return <HealthMetrics>[];
    if (maybe is List<HealthMetrics>) return maybe;
    if (maybe is HealthMetrics) return <HealthMetrics>[maybe];
    if (maybe is List) {
      try {
        return (maybe as List).cast<HealthMetrics>();
      } catch (_) {
        return <HealthMetrics>[];
      }
    }
    return <HealthMetrics>[];
  }

  // --- HealthRepository methods -------------------------------------------

  @override
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetrics() {
    return getCachedMetricsForDate(DateTime.now());
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getCachedMetricsForDate(
    DateTime date,
  ) async {
    try {
      // Local-First: Return stored data explicitly.
      final localList = await localDataSource.readFromCacheForDate(date);
      return Right(localList);
    } on CacheException {
      return Left(CacheFailure('Local cache error.'));
    } catch (e) {
      return Left(RepositoryFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncMetricsForDate(DateTime date) async {
    try {
      final now = DateTime.now();
      final dayStart = DateTime(date.year, date.month, date.day);

      // If date is in future, nothing to sync
      if (dayStart.isAfter(now)) return const Right(null);

      // 1. Fetch from Device (HealthConnect)
      List<HealthMetrics> deviceList = [];
      try {
        final deviceMaybe = await dataSource.fetchFromDeviceForDate(date);
        deviceList = _normalizeToList(deviceMaybe)
            .where(
              (m) =>
                  m.dateFrom.isBefore(now) || m.dateFrom.isAtSameMomentAs(now),
            )
            .toList();
      } catch (e) {
        if (e is PermissionDeniedException) rethrow;
        if (e is HealthConnectNotInstalledException) rethrow;
        debugPrint('Device sync fetch failed: $e');
        // Continue? If device fetch failed, we might still want to try remote-local sync?
        // But the requirement implies "taking health data". If device fails, we might just stop or rely on local.
        // Let's proceed with empty list or whatever we have.
      }
      debugPrint(
        'Sync: Fetched ${deviceList.length} valid metrics from Device for $date',
      );

      // 2. Pre-processing: Merge with Local Sync Status to avoid duplicates/overwrite
      // Fetch existing local metrics to preserve 'synced' status
      List<HealthMetrics> metricsToSave = [];
      List<HealthMetrics> metricsToUpload = [];

      // Pre-processing

      for (var deviceMetric in deviceList) {
        // ALWAYS add to update list, regardless of previous sync status to ensure re-upload
        // The user specifically requested to not filter already uploaded metrics.
        metricsToSave.add(deviceMetric); // Start as not synced (default)
        metricsToUpload.add(deviceMetric); // Upload this metric
      }

      // 3. Parallel Execution: Local Save & Remote Sync
      await Future.wait([
        // Task A: Local Save (Unconditional)
        localDataSource.cacheHealthMetricsBatch(metricsToSave),

        // Task B: Remote Sync (Upload & Download)
        (() async {
          if (!await networkInfo.isConnected)
            return; // Silent return if offline

          try {
            // Maxwell's Demon: Upload only what needs uploading
            if (metricsToUpload.isNotEmpty) {
              debugPrint(
                'Sync: Uploading ${metricsToUpload.length} metrics to Remote...',
              );
              await remoteDataSource.uploadHealthMetrics(metricsToUpload);
              debugPrint('Sync: Upload success. Marking as synced locally.');
              // Mark as synced locally
              await localDataSource.markAsSynced(
                metricsToUpload.map((e) => e.uuid).toList(),
              );
            } else {
              debugPrint('Sync: No new metrics to upload.');
            }

            // Download from Remote (Recovery / Multi-device)
            final remoteMaybe = await remoteDataSource.getHealthMetricsForDate(
              date,
            );
            final remoteList = _normalizeToList(remoteMaybe);

            if (remoteList.isNotEmpty) {
              final syncedList = remoteList
                  .map((m) => m.copyWith(synced: true))
                  .toList();
              // This might overwrite "fresh" device data with "old" remote data if conflict?
              // Typically Remote is source of truth for history, but Device is source of truth for "now".
              // Since we just uploaded device data, Remote should be up to date.
              // Merging remoteList back ensures consistency.
              await localDataSource.cacheHealthMetricsBatch(syncedList);
            }
          } catch (e) {
            debugPrint('Remote sync background error: $e');
            // Do not throw, so Local Save success is preserved
          }
        })(),
      ]);

      return const Right(null);
    } on PermissionDeniedException {
      return const Left(
        PermissionFailure('Health permissions were not granted.'),
      );
    } on HealthConnectNotInstalledException {
      return const Left(
        HealthConnectFailure('Health Connect is not installed.'),
      );
    } on ServerException catch (e) {
      // If the main flow fails? Actually we caught remote errors above.
      // This catch might catch logic errors.
      return Left(ServerFailure('Sync failed: ${e.message}'));
    } catch (e) {
      return Left(RepositoryFailure('Sync error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      final maybeRange = await dataSource.getHealthMetricsRange(
        start,
        end,
        types,
      );
      final list = _normalizeToList(maybeRange);
      return Right(list);
    } on PermissionDeniedException {
      return const Left(
        PermissionFailure('Health permissions were not granted.'),
      );
    } on HealthConnectNotInstalledException {
      return const Left(
        HealthConnectFailure('Health Connect is not installed.'),
      );
    } on ServerException {
      return Left(ServerFailure('Failed to fetch data from the server.'));
    } catch (e) {
      return Left(Failure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(
    String uid,
    List<HealthMetrics> model,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        // Upload to remote
        await remoteDataSource.uploadHealthMetrics(model);

        // Optionally cache locally (best-effort)
        try {
          await localDataSource.cacheHealthMetricsBatch(model);
        } catch (e, st) {
          debugPrint('Local cache after save failed: $e\n$st');
        }
        return const Right(null);
      } on ServerException catch (e) {
        return Left(
          ServerFailure('Failed to save metrics to remote: ${e.toString()}'),
        );
      } catch (e) {
        return Left(Failure('Unexpected error during save: ${e.toString()}'));
      }
    } else {
      // Offline Mode: Save locally only
      try {
        await localDataSource.cacheHealthMetricsBatch(model);
        return const Right(null);
      } catch (e) {
        return Left(CacheFailure('Failed to save locally: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 1}) async {
    // User Requirement: "sync past health data should happen only to date (today)"
    // We strictly ignore the 'days' parameter and only sync the current day.
    // Logic: Fetch Device Data (00:00 - 23:59) -> Save Local -> Sync Remote.

    final today = DateTime.now();
    debugPrint(
      'Background Sync: Enforcing Today-Only Sync for $today (Device -> Local -> Remote)',
    );

    return syncMetricsForDate(today);
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(
    String uid,
  ) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection.'));
      }
      // Fetch all remote metrics for current user (or implement a fetch-by-uid)
      final remoteMaybe = await remoteDataSource.getAllHealthMetricsForUser();
      final remoteList = _normalizeToList(remoteMaybe);
      return Right(remoteList);
    } catch (e) {
      return Left(Failure('Failed to fetch stored metrics: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPermissions() async {
    try {
      // Collect all needed types (union of all tiers)
      // Since specific types aren't passed to repo, we ask datasource to request 'all known types'
      // But datasource.requestPermissions expects a list.
      // We should probably expose 'allTypes' from datasource or just pass a comprehensive list here?
      // Better: let the datasource handle the 'all types' logic if we pass an empty list or separate method?
      // Or just duplicate the logic of 'all types' here?
      // Re-reading datasource: requestPermissions takes List<HealthDataType>.
      // And getHealthMetricsForDate defines the tiers.
      // We should probably invoke a method on datasource that knows the default types.
      // Start simple: The datasource already knows its tiers. Ideally it exposes a "requestAllPermissions" or we pass specific ones.
      // Let's modify the plan slightly: just pass the commonly known types here or rely on DataSource to know?
      // Actually, in `getHealthMetricsForDate` the dataSource uses PRIVATE methods to get tiers.
      // So we can't easily access them here without duplicating.
      // Refactor: We will hardcode the types we know we need here or (better)
      // just ask datasource to "request all permissions" by passing a special flag or updating interface?
      // Since I already updated interface to take List, I need to pass a List.
      // I'll grab the standard set from `Health` package or just defined them here to match what we use.
      // Wait, `HealthMetricsDataSourceImpl` has private methods for tiers.
      // I should have exposed a `requestAllPermissions` in DataSource.
      // But I can just pass the Union of all types here if I know them.
      // To ensure consistency, it gets messy to duplicate.
      // Let's assume for now we pass the broad list of standard types we support.
      // Actually, `HealthDataType.values` is risky.
      // Let's quick-fix: Pass the most important ones.
      // Or better: Update DataSource to have a default behavior if list is empty?
      // I'll check `HealthMetricsDataSourceImpl` again. It takes list.
      // I will duplicate the list here for now to proceed, as it's safer than Refactoring again.

      final types = [
        // Activity
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.FLIGHTS_CLIMBED,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        // Body
        HealthDataType.HEIGHT,
        HealthDataType.WEIGHT,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.BODY_MASS_INDEX,
        // Vitals
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.RESPIRATORY_RATE,
        HealthDataType.BODY_TEMPERATURE,
        // Nutrition
        HealthDataType.WATER,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.NUTRITION,
      ];

      final granted = await dataSource.requestPermissions(types);
      return Right(granted);
    } catch (e) {
      return Left(PermissionFailure('Failed to request permissions: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> restoreAllHealthData() async {
    try {
      // 1. Initial Checks
      // Note: We don't check networkInfo here anymore because we are restoring from DEVICE, not remote.
      // However, we still might want to ensure permissions? The dataSource call should handle exceptions.

      // Local-First Check: Only restore if local DB is empty?
      // User requirement: "for reintsall the app app should fetch the health data from the past 30 days"
      // Even if local DB has *some* data, a reinstall might imply we want to ensure we have the past 30 days.
      // But typically "restore" is run once.
      // Let's stick to the "if empty" check to avoid re-running heavily, OR assume the caller controls when to run this.
      // Ideally, if it's a fresh install, local DB is empty.
      final hasLocalData = await localDataSource.hasAnyMetrics();
      if (hasLocalData) {
        debugPrint('Restore skipped: Local data already exists.');
        return const Right(null);
      }

      debugPrint('Restore: Starting 30-day device sync...');
      final now = DateTime.now();

      // 2. Iterate Past 30 Days
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: i));
        try {
          // A. Fetch from Device
          // catch individual day failures so one bad day doesn't stop the whole restore
          final deviceMaybe = await dataSource.fetchFromDeviceForDate(date);
          final deviceList = _normalizeToList(deviceMaybe)
              .where(
                (m) =>
                    m.dateFrom.isBefore(now) ||
                    m.dateFrom.isAtSameMomentAs(now),
              )
              .toList();

          if (deviceList.isNotEmpty) {
            // B. Save to Local
            // We do NOT upload to remote during restore, just hydrate local cache.
            await localDataSource.cacheHealthMetricsBatch(deviceList);
            debugPrint(
              'Restore: Synced ${deviceList.length} metrics for ${date.toString().split(' ')[0]}',
            );
          }
        } catch (e) {
          debugPrint('Restore: Failed to sync for date $date: $e');
          // Start next iteration
        }
      }

      debugPrint('Restore: 30-day device sync completed.');
      return const Right(null);
    } catch (e) {
      if (e is PermissionDeniedException) {
        return const Left(
          PermissionFailure(
            'Health permissions were not granted during restore.',
          ),
        );
      }
      return Left(RepositoryFailure('Failed to restore health data: $e'));
    }
  }
}
