import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/entities/daily_activity_summary.dart';
import '../../domain/repositories/activity_repository.dart';
import '../datasources/activity_remote_data_source.dart';
import '../../../health_metrics/data/datasources/health_metrics_data_source.dart';
import 'package:health/health.dart';

class ActivityRepositoryImpl implements ActivityRepository {
  final ActivityRemoteDataSource remoteDataSource;
  final HealthMetricsDataSource healthMetricsDataSource;

  ActivityRepositoryImpl({
    required this.remoteDataSource,
    required this.healthMetricsDataSource,
  });

  @override
  Future<Either<Failure, void>> addActivity(ActivityLog activity) async {
    try {
      ActivityLog logToSave = activity;

      // If heart rate is missing, try to fetch it from Health Connect
      if (logToSave.avgHeartRate == null) {
        try {
          final endTime = logToSave.startTime.add(
            Duration(minutes: logToSave.durationMinutes),
          );
          final metrics = await healthMetricsDataSource.getHealthMetricsRange(
            logToSave.startTime,
            endTime,
            [HealthDataType.HEART_RATE],
          );

          if (metrics.isNotEmpty) {
            double totalHr = 0;
            int count = 0;
            for (var m in metrics) {
              if (m.value > 0) {
                totalHr += m.value;
                count++;
              }
            }
            if (count > 0) {
              final avg = (totalHr / count).round();
              logToSave = ActivityLog(
                id: logToSave.id,
                userId: logToSave.userId,
                activityType: logToSave.activityType,
                customActivityName: logToSave.customActivityName,
                startTime: logToSave.startTime,
                durationMinutes: logToSave.durationMinutes,
                caloriesBurned: logToSave.caloriesBurned,
                avgHeartRate: avg,
                createdAt: logToSave.createdAt,
                updatedAt: logToSave.updatedAt,
                notes: logToSave.notes,
              );
            }
          }
        } catch (e) {
          // Ignore failures in fetching HR, proceed with original log
        }
      }

      await remoteDataSource.logActivity(logToSave);
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
