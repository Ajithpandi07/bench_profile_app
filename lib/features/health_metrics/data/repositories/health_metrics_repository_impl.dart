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

  // Full restore helper: fetch ALL remote metrics for current user and upsert locally.
  Future<Either<Failure, void>> _restoreLocalFromRemoteAll() async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure('No internet connection for restore'));
      }

      final remoteMaybe = await remoteDataSource.getAllHealthMetricsForUser();
      final remoteList = _normalizeToList(remoteMaybe);

      if (remoteList.isEmpty) return const Right(null);

      await localDataSource.cacheHealthMetricsBatch(remoteList);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure('Remote restore failed: ${e.message}'));
    } catch (e) {
      return Left(RepositoryFailure('Restore failed: ${e.toString()}'));
    }
  }

  // --- HealthRepository methods -------------------------------------------

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetrics() {
    return getHealthMetricsForDate(DateTime.now());
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getHealthMetricsForDate(DateTime date) async {
    try {
      final now = DateTime.now();
      final dayStart = DateTime(date.year, date.month, date.day);
      if (dayStart.isAfter(now)) return const Right(<HealthMetrics>[]);

      // Attempt Device -> Remote -> Local (best-effort) if online
      if (await networkInfo.isConnected) {
        try {
          final deviceMaybe = await dataSource.getHealthMetricsForDate(date);
          final deviceList = _normalizeToList(deviceMaybe)
              .where((m) => m.dateFrom.isBefore(now) || m.dateFrom.isAtSameMomentAs(now))
              .toList();

          // Get remote canonical set for date
          final remoteMaybe = await remoteDataSource.getHealthMetricsForDate(date);
          final remoteList = _normalizeToList(remoteMaybe);
          final remoteUuids = remoteList.map((e) => e.uuid).toSet();

          // Upload only missing
          final toUpload = deviceList.where((p) => !remoteUuids.contains(p.uuid)).toList();
          if (toUpload.isNotEmpty) {
            try {
              await remoteDataSource.uploadHealthMetrics(toUpload);
            } catch (e, st) {
              debugPrint('Upload missing points failed (non-fatal): $e\n$st');
            }
          }

          // Re-fetch canonical remote and cache locally
          final postRemoteMaybe = await remoteDataSource.getHealthMetricsForDate(date);
          final postRemoteList = _normalizeToList(postRemoteMaybe);
          if (postRemoteList.isNotEmpty) {
            try {
              await localDataSource.cacheHealthMetricsBatch(postRemoteList);
            } catch (e, st) {
              debugPrint('Cache remote -> local failed (non-fatal): $e\n$st');
            }
          }
        } catch (e, st) {
          debugPrint('Daily sync attempt failed (non-fatal): $e\n$st');
        }
      }

      // Read from local (UI source-of-truth)
      try {
        final localList = await localDataSource.getAllHealthMetricsForDate(date);

        // If local is empty and we have network, do a full restore from remote
        if (localList.isEmpty && await networkInfo.isConnected) {
          final restoreRes = await _restoreLocalFromRemoteAll();
          if (restoreRes.isRight()) {
            final restored = await localDataSource.getAllHealthMetricsForDate(date);
            return Right(restored);
          } else {
            // restore failed => try remote fallback for this date
            try {
              final remoteFallback = await remoteDataSource.getHealthMetricsForDate(date);
              return Right(_normalizeToList(remoteFallback));
            } catch (e) {
              debugPrint('Remote fallback after failed restore also failed: $e');
              return Right(localList); // empty
            }
          }
        }

        return Right(localList);
      } catch (e) {
        debugPrint('Local read failed: $e');
        // Local failed -> try remote fallback and cache
        if (await networkInfo.isConnected) {
          try {
            final remoteFallback = await remoteDataSource.getHealthMetricsForDate(date);
            final remoteList = _normalizeToList(remoteFallback);
            if (remoteList.isNotEmpty) {
              try {
                await localDataSource.cacheHealthMetricsBatch(remoteList);
              } catch (e, st) {
                debugPrint('Cache after remote fallback failed: $e\n$st');
              }
            }
            return Right(remoteList);
          } catch (e2) {
            return Left(CacheFailure('Local read failed and remote fallback failed: ${e2.toString()}'));
          }
        }
        return Left(CacheFailure('Local read failed: ${e.toString()}'));
      }
    } on PermissionDeniedException {
      return const Left(PermissionFailure('Health permissions were not granted.'));
    } on ServerException catch (e) {
      return Left(ServerFailure('Remote error: ${e.message}'));
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
      final maybeRange = await dataSource.getHealthMetricsRange(start, end, types);
      final list = _normalizeToList(maybeRange);
      return Right(list);
    } on PermissionDeniedException {
      return const Left(PermissionFailure('Health permissions were not granted.'));
    } on ServerException {
      return Left(ServerFailure('Failed to fetch data from the server.'));
    } catch (e) {
      return Left(Failure('Unexpected error: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, List<HealthMetrics> model) async {
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
        return Left(ServerFailure('Failed to save metrics to remote: ${e.toString()}'));
      } catch (e) {
        return Left(Failure('Unexpected error during save: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection. Could not save metrics.'));
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
  Future<Either<Failure, List<HealthMetrics>?>> getStoredHealthMetrics(String uid) async {
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
