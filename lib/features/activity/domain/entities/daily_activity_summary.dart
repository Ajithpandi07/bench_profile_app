import 'package:equatable/equatable.dart';

class DailyActivitySummary extends Equatable {
  final DateTime date;
  final double totalCalories;
  final int totalDuration;

  const DailyActivitySummary({
    required this.date,
    required this.totalCalories,
    required this.totalDuration,
  });

  @override
  List<Object?> get props => [date, totalCalories, totalDuration];
}
