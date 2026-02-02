import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/entities/daily_activity_summary.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_remote_data_source.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;

  ActivityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, void>> addActivity(ActivityLog activity) async {
    try {
      await remoteDataSource.logActivity(activity);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ActivityLog>>> getActivitiesForDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final logs = await remoteDataSource.getActivitiesForDate(date);
      return Right(logs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyActivitySummary>>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final summaries = await remoteDataSource.getDailySummaries(start, end);
      return Right(summaries);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteActivity(
    String activityId,
    DateTime date,
  ) async {
    try {
      await remoteDataSource.deleteActivity(activityId, date);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateActivity(ActivityLog activity) async {
    try {
      await remoteDataSource.updateActivity(activity);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
