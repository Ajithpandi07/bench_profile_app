import 'package:equatable/equatable.dart';
import '../../domain/entities/activity_log.dart';

abstract class ActivityEvent extends Equatable {
  const ActivityEvent();

  @override
  List<Object?> get props => [];
}

class LoadActivitiesForDate extends ActivityEvent {
  final DateTime date;

  const LoadActivitiesForDate(this.date);

  @override
  List<Object> get props => [date];
}

class AddActivityEvent extends ActivityEvent {
  final ActivityLog activity;
  final bool wasTargetReached;

  const AddActivityEvent(this.activity, {this.wasTargetReached = false});

  @override
  List<Object> get props => [activity, wasTargetReached];
}

class UpdateActivityEvent extends ActivityEvent {
  final ActivityLog activity;
  final bool wasTargetReached;

  const UpdateActivityEvent(this.activity, {this.wasTargetReached = false});

  @override
  List<Object> get props => [activity, wasTargetReached];
}

class DeleteActivityEvent extends ActivityEvent {
  final String activityId;
  final DateTime date;

  const DeleteActivityEvent(this.activityId, this.date);

  @override
  List<Object> get props => [activityId, date];
}

class DeleteMultipleActivities extends ActivityEvent {
  final List<String> activityIds;
  final DateTime date;

  const DeleteMultipleActivities(this.activityIds, this.date);

  @override
  List<Object> get props => [activityIds, date];
}

class LoadActivityStats extends ActivityEvent {
  final DateTime? start;
  final DateTime? end;

  const LoadActivityStats({this.start, this.end});

  @override
  List<Object?> get props => [start, end];
}
