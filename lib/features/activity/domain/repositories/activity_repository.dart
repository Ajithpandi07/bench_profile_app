import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/activity_log.dart';
import '../entities/daily_activity_summary.dart';

abstract class ActivityRepository {
  Future<Either<Failure, void>> addActivity(ActivityLog activity);
  Future<Either<Failure, List<ActivityLog>>> getActivitiesForDate(
    String userId,
    DateTime date,
  );
  Future<Either<Failure, void>> deleteActivity(
    String activityId,
    DateTime date,
  );
  Future<Either<Failure, void>> updateActivity(ActivityLog activity);
  Future<Either<Failure, List<DailyActivitySummary>>> getDailySummaries(
    DateTime start,
    DateTime end,
  );
}
