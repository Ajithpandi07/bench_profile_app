import 'package:equatable/equatable.dart';
import '../../domain/entities/hydration_daily_summary.dart';
import '../../domain/domain.dart';

abstract class HydrationState extends Equatable {
  const HydrationState();

  @override
  List<Object> get props => [];
}

class HydrationInitial extends HydrationState {}

class HydrationSaving extends HydrationState {}

class HydrationLoading extends HydrationState {}

class HydrationSuccess extends HydrationState {}

class HydrationDeletedSuccess extends HydrationState {}

class HydrationLogsLoaded extends HydrationState {
  final List<HydrationLog> logs;
  final DateTime date;
  final double? targetWater;
  final String? snackbarMessage;

  const HydrationLogsLoaded(
    this.logs,
    this.date, {
    this.targetWater,
    this.snackbarMessage,
  });

  @override
  List<Object> get props => [
    logs,
    date,
    if (targetWater != null) targetWater!,
    if (snackbarMessage != null) snackbarMessage!,
  ];
}

class HydrationFailure extends HydrationState {
  final String message;

  const HydrationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class HydrationStatsLoaded extends HydrationState {
  final List<HydrationDailySummary> stats;
  final DateTime startDate;
  final DateTime endDate;

  const HydrationStatsLoaded(this.stats, this.startDate, this.endDate);

  @override
  List<Object> get props => [stats, startDate, endDate];
}
