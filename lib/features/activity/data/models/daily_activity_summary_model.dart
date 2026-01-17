import '../../domain/entities/daily_activity_summary.dart';

class DailyActivitySummaryModel extends DailyActivitySummary {
  const DailyActivitySummaryModel({
    required super.date,
    required super.totalCalories,
    required super.totalDuration,
  });
}
