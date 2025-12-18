// lib/features/health_metrics/data/repositories/health_metrics_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import 'package:flutter/foundation.dart';

import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/core/network/network_info.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import '../../domain/repositories/health_repository.dart';

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
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() {
    return getHealthMetricsForDate(DateTime.now());
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(
      DateTime date) async {
    try {
      final now = DateTime.now();
      final dayStart = DateTime(date.year, date.month, date.day);
      if (dayStart.isAfter(now)) return const Right(<HealthMetrics>[]);

      // 1. Fetch from Device (HealthConnect)
      // We do NOT save this to local directly anymore.
      // The flow is strictly: Device -> Remote -> Local.
      List<HealthMetrics> deviceList = [];
      try {
        final deviceMaybe = await dataSource.getHealthMetricsForDate(date);
        deviceList = _normalizeToList(deviceMaybe)
            .where((m) =>
                m.dateFrom.isBefore(now) || m.dateFrom.isAtSameMomentAs(now))
            .toList();
      } catch (e) {
        if (e is! PermissionDeniedException) {
          debugPrint('Device fetch failed: $e');
        }
      }

      // 2. Sync Logic: Device -> Remote -> Local
      if (await networkInfo.isConnected) {
        try {
          // A. DEVICE -> REMOTE (Upload)
          // We assume Remote is the source of truth, so we push our fresh device data there first.
          if (deviceList.isNotEmpty) {
            // Optional: Filter dupes against remote if needed, but "Upsert" on server handles it usually.
            // For now, we attempt to upload all fresh device data found.
            await remoteDataSource.uploadHealthMetrics(deviceList);
          }

          // B. REMOTE -> LOCAL (Download & Cache)
          // Now that Remote is updated, we fetch from it to update our Local "Source of Truth".
          final remoteMaybe =
              await remoteDataSource.getHealthMetricsForDate(date);
          final remoteList = _normalizeToList(remoteMaybe);

          if (remoteList.isNotEmpty) {
            // Mark as synced since it came from remote
            final syncedList =
                remoteList.map((m) => m.copyWith(synced: true)).toList();
            await localDataSource.cacheHealthMetricsBatch(syncedList);
          }
        } catch (e) {
          debugPrint('Strict sync (Device->Remote->Local) failed: $e');
          // Fallback: If sync fails, we might want to temporarily show existing local?
        }
      } else {
        // Offline Fallback:
        // Since we cannot sync Device->Remote, we technically "lose" the device view if we don't cache it.
        // However, user requested "Device -> Local should NOT be".
        // But for offline usability, we might display Local data as is.
        // NOTE: If offline, users won't see new device steps until they go online. This follows the strict request.
      }

      // 3. Return Local (The Source of Truth)
      final localList = await localDataSource.getAllHealthMetricsForDate(date);

      // If local is empty (and maybe we are offline or sync failed),
      // check if we should try a "Last Resort" remote fetch if we think we have connectivity?
      // (Already tried in step 2).

      return Right(localList);
    } on PermissionDeniedException {
      return const Left(
          PermissionFailure('Health permissions were not granted.'));
    } on CacheException {
      return Left(CacheFailure('Local cache error.'));
    } catch (e) {
      return Left(RepositoryFailure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      final maybeRange =
          await dataSource.getHealthMetricsRange(start, end, types);
      final list = _normalizeToList(maybeRange);
      return Right(list);
    } on PermissionDeniedException {
      return const Left(
          PermissionFailure('Health permissions were not granted.'));
    } on ServerException {
      return Left(ServerFailure('Failed to fetch data from the server.'));
    } catch (e) {
      return Left(Failure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(
      String uid, List<HealthMetrics> model) async {
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
            ServerFailure('Failed to save metrics to remote: ${e.toString()}'));
      } catch (e) {
        return Left(Failure('Unexpected error during save: ${e.toString()}'));
      }
    } else {
      return const Left(
          NetworkFailure('No internet connection. Could not save metrics.'));
    }
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 30}) async {
    return Left(RepositoryFailure('Sync error:'));

    // try {
    //   final today = DateTime.now();
    //   final startDate = DateTime(today.year, today.month, today.day).subtract(Duration(days: days));
    //   final types = HealthDataType.values;

    //   final deviceMaybe = await dataSource.getHealthMetricsRange(startDate, today, types);
    //   final deviceList = _normalizeToList(deviceMaybe);

    //   if (deviceList.isEmpty) {
    //     debugPrint('No device metrics found for range $startDate..$today');
    //     return const Right(null);
    //   }

    //   // Group device points by day
    //   final Map<String, List<HealthMetrics>> byDate = {};
    //   for (final p in deviceList) {
    //     final key = '${p.dateFrom.year}-${p.dateFrom.month.toString().padLeft(2, '0')}-${p.dateFrom.day.toString().padLeft(2, '0')}';
    //     byDate.putIfAbsent(key, () => []).add(p);
    //   }

    //   for (final entry in byDate.entries) {
    //     final parts = entry.key.split('-');
    //     final d = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    //     final deviceForDay = entry.value;

    //     // fetch remote points for that day (best-effort)
    //     List<HealthMetrics> remoteForDay = [];
    //     try {
    //       final remoteMaybe = await remoteDataSource.getHealthMetricsForDate(d);
    //       remoteForDay = _normalizeToList(remoteMaybe);
    //     } catch (e) {
    //       debugPrint('Failed to fetch remote metrics for $d: $e');
    //     }

    //     final remoteUuids = remoteForDay.map((e) => e.uuid).toSet();
    //     final toUpload = deviceForDay.where((p) => !remoteUuids.contains(p.uuid)).toList();

    //     if (toUpload.isNotEmpty) {
    //       try {
    //         await remoteDataSource.uploadHealthMetrics(toUpload);
    //         debugPrint('Uploaded ${toUpload.length} missing points for $d');
    //       } catch (e, st) {
    //         debugPrint('Upload failed for $d: $e\n$st');
    //       }
    //     } else {
    //       debugPrint('No missing points to upload for $d');
    //     }
    //   }

    //   return const Right(null);
    // } on PermissionDeniedException {
    //   return const Left(PermissionFailure('Health permissions were not granted.'));
    // } on ServerException catch (e) {
    //   return Left(ServerFailure('Remote server error during sync: ${e.message}'));
    // } catch (e) {
    //   return Left(RepositoryFailure('Sync error: ${e.toString()}'));
    // }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(
      String uid) async {
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
}
