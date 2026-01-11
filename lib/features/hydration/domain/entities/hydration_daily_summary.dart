import 'package:equatable/equatable.dart';

class HydrationDailySummary extends Equatable {
  final DateTime date;
  final double totalLiters;

  const HydrationDailySummary({required this.date, required this.totalLiters});

  @override
  List<Object?> get props => [date, totalLiters];
}
