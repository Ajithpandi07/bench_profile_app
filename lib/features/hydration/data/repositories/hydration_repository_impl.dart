import 'package:dartz/dartz.dart';
import '../../../../../core/core.dart';
import '../../domain/domain.dart';
import '../../domain/entities/hydration_daily_summary.dart';
import '../datasources/hydration_remote_data_source.dart';

class HydrationRepositoryImpl implements HydrationRepository {
  final HydrationRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HydrationRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> logWaterIntake(HydrationLog log) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logWaterIntake(log);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to log hydration: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection.'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteHydrationLog(
    String id,
    DateTime date,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteHydrationLog(id, date);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure('Failed to delete hydration log: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection.'));
    }
  }

  @override
  Future<Either<Failure, List<HydrationLog>>> getHydrationLogsForDate(
    DateTime date,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final logs = await remoteDataSource.getHydrationLogsForDate(date);
        return Right(logs);
      } catch (e) {
        return Left(ServerFailure('Failed to fetch hydration logs: $e'));
      }
    } else {
      // Since requirements said "Remote Only" for now, we just fail if no net.
      // If caching was needed we'd fetch local here.
      return const Left(NetworkFailure('No internet connection.'));
    }
  }

  @override
  Future<Either<Failure, List<HydrationDailySummary>>> getHydrationStats({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final stats = await remoteDataSource.getHydrationStats(
          startDate,
          endDate,
        );
        return Right(stats);
      } catch (e) {
        return Left(ServerFailure('Failed to fetch hydration stats: $e'));
      }
    } else {
      return const Left(NetworkFailure('No internet connection.'));
    }
  }
}
