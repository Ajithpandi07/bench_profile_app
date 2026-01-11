import 'package:equatable/equatable.dart';

class DailyMealSummary extends Equatable {
  final DateTime date;
  final double totalCalories;

  const DailyMealSummary({required this.date, required this.totalCalories});

  @override
  List<Object?> get props => [date, totalCalories];
}
