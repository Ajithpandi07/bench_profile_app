import 'package:dartz/dartz.dart';
import '../../../../core/core.dart';
import '../entities/hydration_log.dart';
import '../entities/hydration_daily_summary.dart';

abstract class HydrationRepository {
  /// Uploads a single hydration log to the remote server.
  /// Does not cache locally.
  Future<Either<Failure, void>> logWaterIntake(HydrationLog log);

  /// Fetches hydration logs for a specific date from remote server.
  Future<Either<Failure, List<HydrationLog>>> getHydrationLogsForDate(
    DateTime date,
  );

  /// Fetches daily summaries for a given date range.
  Future<Either<Failure, List<HydrationDailySummary>>> getHydrationStats({
    required DateTime startDate,
    required DateTime endDate,
  });
}
