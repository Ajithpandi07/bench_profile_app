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
      // Local-First: Return stored data explicitly.
      final localList = await localDataSource.getAllHealthMetricsForDate(date);
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
        final deviceMaybe = await dataSource.getHealthMetricsForDate(date);
        deviceList = _normalizeToList(deviceMaybe)
            .where((m) =>
                m.dateFrom.isBefore(now) || m.dateFrom.isAtSameMomentAs(now))
            .toList();
      } catch (e) {
        if (e is! PermissionDeniedException) {
          debugPrint('Device sync fetch failed: $e');
        }
        // If critical permission failure, we might rethrow or return Left,
        // but for sync often we want to just log and continue if possible or return failure.
        if (e is PermissionDeniedException)
          rethrow; // Let caller process permissions
      }

      if (!await networkInfo.isConnected) {
        // Offline: If we have device data, we can still cache it locally?
        // Actually, user flow says "Background sync ... take health data to remote to locally".
        // But optimization: cache device data locally immediately for offline support?
        // User asked "take health data to remote to locally".
        // But standard offline support implies caching device data directly is usually fine.
        // However, to stick to "Device -> Remote -> Local" strict pattern:
        // We cannot proceed without internet.
        return const Left(NetworkFailure('No internet for sync.'));
      }

      // 2. DEVICE -> REMOTE (Upload)
      if (deviceList.isNotEmpty) {
        await remoteDataSource.uploadHealthMetrics(deviceList);
      }

      // 3. REMOTE -> LOCAL (Download & Cache)
      final remoteMaybe = await remoteDataSource.getHealthMetricsForDate(date);
      final remoteList = _normalizeToList(remoteMaybe);

      if (remoteList.isNotEmpty) {
        final syncedList =
            remoteList.map((m) => m.copyWith(synced: true)).toList();
        await localDataSource.cacheHealthMetricsBatch(syncedList);
      }

      return const Right(null);
    } on PermissionDeniedException {
      return const Left(
          PermissionFailure('Health permissions were not granted.'));
    } on ServerException catch (e) {
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
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection during sync'));
      }

      final today = DateTime.now();
      // Only look back 'days' amount to avoid massive syncs.
      // For "Seamless", we iterate day by day or just range.
      // Since health package works best with daily batches, let's iterate.
      // However, to be efficient, we can try range fetch if supported.
      // Given previous "today restriction", let's respect that "background sync"
      // might need to catch up on missed days.

      for (int i = 0; i < days; i++) {
        final date = today.subtract(Duration(days: i));
        // START OF DAY
        final d = DateTime(date.year, date.month, date.day);

        debugPrint('Background Sync: Processing $d...');

        // 1. Fetch DEVICE (Device Source of Truth for raw data)
        // We use the same 'getHealthMetricsForDate' logic which now grabs just that day (no massive lookback)
        // Note: This relies on 'dataSource' being safe to call in background (it is).
        List<HealthMetrics> deviceData = [];
        try {
          final deviceMaybe = await dataSource.getHealthMetricsForDate(d);
          deviceData = _normalizeToList(deviceMaybe);
        } catch (e) {
          debugPrint('Background Sync: Device fetch failed for $d: $e');
          // If device fetch fails (e.g. permissions locked in background), we skip this day
          continue;
        }

        if (deviceData.isEmpty) {
          debugPrint('Background Sync: No device data for $d');
          // Even if device is empty, should we check if Remote has data to pull down?
          // Yes, "Seamless Device -> Remote -> Local" implies pulling remote too.
        } else {
          // 2. DEVICE -> REMOTE (Upload)
          // We indiscriminately upload fresh device data. Remote handles merging.
          await remoteDataSource.uploadHealthMetrics(deviceData);
          debugPrint(
              'Background Sync: Uploaded ${deviceData.length} items for $d');
        }

        // 3. REMOTE -> LOCAL (Download & updates Local Source of Truth)
        final remoteMaybe = await remoteDataSource.getHealthMetricsForDate(d);
        final remoteList = _normalizeToList(remoteMaybe);

        if (remoteList.isNotEmpty) {
          final syncedList =
              remoteList.map((m) => m.copyWith(synced: true)).toList();
          await localDataSource.cacheHealthMetricsBatch(syncedList);
          debugPrint(
              'Background Sync: Cached ${syncedList.length} items locally for $d');
        }
      }

      return const Right(null);
    } on PermissionDeniedException {
      return const Left(
          PermissionFailure('Health permissions were not granted.'));
    } on ServerException catch (e) {
      return Left(
          ServerFailure('Remote server error during sync: ${e.message}'));
    } catch (e) {
      return Left(RepositoryFailure('Sync error: ${e.toString()}'));
    }
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
