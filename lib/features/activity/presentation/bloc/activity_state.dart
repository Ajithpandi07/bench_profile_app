import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_log.dart';
import '../../domain/entities/daily_activity_summary.dart';

abstract class ActivityState extends Equatable {
  const ActivityState();

  @override
  List<Object> get props => [];
}

class ActivityInitial extends ActivityState {}

class ActivityLoading extends ActivityState {}

class ActivitiesLoaded extends ActivityState {
  final List<ActivityLog> activities;
  final DateTime date;

  const ActivitiesLoaded(this.activities, this.date);

  @override
  List<Object> get props => [activities, date];
}

class ActivityOperationFailure extends ActivityState {
  final String message;

  const ActivityOperationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class ActivityOperationSuccess extends ActivityState {
  final String message;
  final bool wasTargetReached;

  const ActivityOperationSuccess(this.message, {this.wasTargetReached = false});

  @override
  List<Object> get props => [message, wasTargetReached];
}

class ActivityStatsLoaded extends ActivityState {
  final List<DailyActivitySummary> summaries;

  const ActivityStatsLoaded(this.summaries);

  @override
  List<Object> get props => [summaries];
}
