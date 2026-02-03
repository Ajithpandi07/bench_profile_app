import 'package:equatable/equatable.dart';
import '../../domain/domain.dart';

abstract class HydrationEvent extends Equatable {
  const HydrationEvent();

  @override
  List<Object> get props => [];
}

class LogHydration extends HydrationEvent {
  final HydrationLog log;
  final bool wasTargetReached;

  const LogHydration(this.log, {this.wasTargetReached = false});

  @override
  List<Object> get props => [log, wasTargetReached];
}

class LoadHydrationLogs extends HydrationEvent {
  final DateTime date;
  const LoadHydrationLogs(this.date);

  @override
  List<Object> get props => [date];
}

class LoadHydrationStats extends HydrationEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadHydrationStats({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

class DeleteHydrationLog extends HydrationEvent {
  final String id;
  final DateTime date;

  const DeleteHydrationLog(this.id, this.date);

  @override
  List<Object> get props => [id, date];
}

class DeleteAllHydrationForDate extends HydrationEvent {
  final DateTime date;
  const DeleteAllHydrationForDate(this.date);

  @override
  List<Object> get props => [date];
}

class DeleteMultipleHydrationLogs extends HydrationEvent {
  final List<String> logIds;
  final DateTime date;

  const DeleteMultipleHydrationLogs({required this.logIds, required this.date});

  @override
  List<Object> get props => [logIds, date];
}
