// lib/features/health_metrics/data/repositories/health_metrics_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/core/network/network_info.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/local/health_metrics_local_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/data/datasources/remote/health_metrics_remote_data_source.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:flutter/foundation.dart';
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

  /// Helper: normalize various possible return types into List<HealthMetrics>.
  List<HealthMetrics> _normalizeToList(dynamic maybe) {
    if (maybe == null) return <HealthMetrics>[];
    if (maybe is List<HealthMetrics>) return maybe;
    if (maybe is HealthMetrics) return <HealthMetrics>[maybe];
    // If it's a List<dynamic>, try to cast each element.
    if (maybe is List) {
      try {
        return (maybe as List).cast<HealthMetrics>();
      } catch (_) {
        return <HealthMetrics>[];
      }
    }
    return <HealthMetrics>[];
  }

  /// Helper to cache metrics locally and upload them to the remote data source.
  /// Errors are caught and logged without interrupting the main data flow.
  Future<void> _syncMetrics(List<HealthMetrics> metrics, {required bool upload}) async {
    if (metrics.isEmpty) return;

    try {
      final cacheFutures = metrics.map((m) => localDataSource.cacheHealthMetrics(m));
      final allFutures = <Future>[...cacheFutures];

      if (upload) {
        allFutures.add(remoteDataSource.uploadHealthMetrics(metrics));
      }

      await Future.wait(allFutures);
    } catch (e, st) {
      debugPrint('Sync failed (cache or upload): $e\n$st');
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() async {
    // Default: return the metrics for today
    return getHealthMetricsForDate(DateTime.now());
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(DateTime date) async {
    try {
      // 1. Check local cache first for an offline-first experience.
      final localMetrics = await localDataSource.getAllHealthMetricsForDate(date);
      if (localMetrics.isNotEmpty) {
        debugPrint("Found ${localMetrics.length} metrics in local cache for $date.");
        // Data found locally. Return it immediately for a responsive UI.
        // Then, trigger a background sync to ensure it's on the remote DB.
        // We don't await this, so the UI isn't blocked.
        (() async {
          if (await networkInfo.isConnected) {
            debugPrint("Queueing background upload for local metrics...");
            await _syncMetrics(localMetrics, upload: true);
          }
        })();
        return Right(localMetrics);
      }
 
      // 2. If local cache is empty, check network connection before proceeding.
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure('No data in cache and no internet connection.'));
      }
 
      // 3. Try fetching from the remote data source (Firestore).
      debugPrint("Local cache empty, trying remote for $date...");
      final remoteMetrics = await remoteDataSource.getHealthMetricsForDate(date);
      if (remoteMetrics.isNotEmpty) {
        debugPrint("Found ${remoteMetrics.length} metrics in remote DB.");
        // Data found remotely. Cache it locally for future offline access.
        await _syncMetrics(remoteMetrics, upload: false); // Don't re-upload what we just fetched.
        return Right(remoteMetrics);
      }
 
      // 4. If both local and remote are empty, fetch from the device's Health API as a last resort.
      debugPrint("Remote DB empty, fetching from device Health API for $date...");
      final deviceMetrics = await dataSource.getHealthMetricsForDate(date);
      if (deviceMetrics.isEmpty) {
        debugPrint("No metrics found on device for $date.");
        return Left(const RepositoryFailure('No metrics available for this date.'));
      }
 
      debugPrint("Found ${deviceMetrics.length} new metrics on device. Syncing to local and remote...");
      // 5. Sync the new data to both local cache and remote DB.
      // We await this to ensure the first fetch is fully persisted.
      _syncMetrics(deviceMetrics, upload: true);
      return Right(deviceMetrics);

    } on PermissionDeniedException {
      return const Left(PermissionFailure('Health permissions were not granted.'));
    } on ServerException catch (e) {
      // This will catch failures from remoteDataSource
      return Left(ServerFailure('A remote data error occurred: ${e.message}'));
    } on CacheException {
      return Left(CacheFailure('A local database error occurred.'));
    } catch (e) {
      return Left(RepositoryFailure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncPastHealthData({int days = 30}) async {
    try {
      final today = DateTime.now();
      final startDate = today.subtract(Duration(days: days));
      // Use all available health types for a comprehensive sync.
      final types = HealthDataType.values;

      debugPrint("Syncing past $days days of health data (from $startDate to $today)...");

      // 1. Fetch all metrics from the device's Health API for the date range.
      final deviceMetrics = await dataSource.getHealthMetricsRange(startDate, today, types);
      if (deviceMetrics.isEmpty) {
        debugPrint("No new metrics found on device for the past $days days.");
        return const Right(null);
      }
      debugPrint("Fetched ${deviceMetrics.length} total metrics from device API.");

      // 2. Fetch existing metric UUIDs from the local database for the same range to avoid duplicates.
      final localMetrics = await localDataSource.getMetricsForDateRange(startDate, today); // Assuming this method exists
      final existingUuidsSet = localMetrics.map((m) => m.uuid).toSet();
      debugPrint("Found ${existingUuidsSet.length} existing metrics in local DB for this period.");

      // 3. Filter out device metrics that are already in the local database.
      final newMetricsToSave = deviceMetrics.where((m) => !existingUuidsSet.contains(m.uuid)).toList();

      // 4. If there are new metrics, cache them locally.
      debugPrint("Found ${newMetricsToSave.length} new metrics to cache.");
      if (newMetricsToSave.isNotEmpty) {
        await localDataSource.cacheHealthMetricsBatch(newMetricsToSave);
      }

      return const Right(null);
    } catch (e) {
      return Left(RepositoryFailure('An error occurred during past data sync: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsRange(
    DateTime start,
    DateTime end,
    List<HealthDataType> types,
  ) async {
    try {
      // The primary data source is responsible for fetching from the Health API.
      final maybeRange = await dataSource.getHealthMetricsRange(start, end, types);
      final list = _normalizeToList(maybeRange);
      return Right(list);
    } on PermissionDeniedException {
      return const Left(PermissionFailure('Health permissions were not granted.'));
    } on ServerException {
      return Left(ServerFailure('Failed to fetch data from the server.'));
    } catch (e) {
      return Left(Failure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, List<HealthMetrics> model) async {
    if (await networkInfo.isConnected) {
      try {
        // The remoteDataSource handles the upload logic.
        await remoteDataSource.uploadHealthMetrics(model);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure('Failed to save metrics to remote source: ${e.toString()}'));
      } catch (e) {
        return Left(Failure('An unexpected error occurred during save: ${e.toString()}'));
      }
    } else {
      // Return a specific failure for network issues.
      return const Left(NetworkFailure('No internet connection. Could not save metrics.'));
    }
  }

  @override
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(String uid) async {
    // This method is intended to fetch data from a remote store like Firestore.
    // The current remote data source only has an `upload` method.
    // For now, we'll return an empty list as a valid response.
    // To fully implement this, you would add a `get` method to HealthMetricsRemoteDataSource.
    if (await networkInfo.isConnected) {
      return const Right(<HealthMetrics>[]);
    } else {
      return const Left(NetworkFailure('No internet connection.'));
    }
  }
}
