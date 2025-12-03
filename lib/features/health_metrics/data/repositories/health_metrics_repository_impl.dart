// health_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:health/health.dart';
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

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsForDate(DateTime date) async {
    try {
      // 1. Try to fetch from local Isar database first
      final localMetrics = await localDataSource.getHealthMetricsForDate(date);
      return Right(localMetrics);
    } on CacheException {
      // 2. If not in cache, fetch from the primary data source (e.g., Health Connect)
      try {
        final newMetrics = await dataSource.getHealthMetricsForDate(date);
        // 3. Cache the new metrics locally in Isar
        localDataSource.cacheHealthMetrics(newMetrics);
        // 4. If online, upload to the remote database (Firestore)
        if (await networkInfo.isConnected) {
          remoteDataSource.uploadHealthMetrics(newMetrics);
        }
        return Right(newMetrics);
      } on PermissionDeniedException {
        return const Left(PermissionFailure( 'Health permissions were not granted.'));
      } on ServerException {
        return Left(ServerFailure('Failed to fetch data from the server.'));
      } catch (e) {
        return Left(Failure('An unexpected error occurred: ${e.toString()}'));
      }
    }
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetrics() async {
    // By default, this method will get the metrics for the current day.
    // This behavior can be changed if a different default is needed.
    return getHealthMetricsForDate(DateTime.now());
  }

  @override
  Future<Either<Failure, HealthMetrics>> getHealthMetricsRange(DateTime start, DateTime end, List<HealthDataType> types) async {
    // This implementation fetches directly from the data source without caching.
    // Caching for date ranges could be added if needed.
    try {
      final metrics = await dataSource.getHealthMetricsForDate(start); // This seems to be the only available method in the datasource for now
      return Right(metrics);
    } on PermissionDeniedException {
      return const Left(PermissionFailure( 'Health permissions were not granted.'));
    } on ServerException {
      return Left(ServerFailure('Failed to fetch data from the server.'));
    } catch (e) {
      return Left(Failure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveHealthMetrics(String uid, HealthMetrics model) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.uploadHealthMetrics(model);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to save metrics to remote source: ${e.toString()}'));
      }
    } else {
      // Optionally, cache the data locally to be uploaded later when online.
      // For now, we return a failure if offline.
      return const Left(NetworkFailure( 'No internet connection. Could not save metrics.'));
    }
  }

  @override
  Future<Either<Failure, HealthMetrics?>> getStoredHealthMetrics(String uid) async {
    // This is a placeholder. A remote data source method would be needed to fetch by UID.
    // For now, it returns null, similar to the Noop repository.
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<HealthMetrics>>> getMetricsForDate(DateTime date) async {
    // This would likely fetch from a local or remote source that returns a list.
    return Right([]);
  }
}
