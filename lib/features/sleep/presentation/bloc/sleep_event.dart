import 'package:equatable/equatable.dart';
import '../../domain/entities/sleep_log.dart';

abstract class SleepEvent extends Equatable {
  const SleepEvent();

  @override
  List<Object> get props => [];
}

class LoadSleepLogs extends SleepEvent {
  final DateTime date;

  const LoadSleepLogs(this.date);

  @override
  List<Object> get props => [date];
}

class LoadSleepStats extends SleepEvent {
  final DateTime startDate;
  final DateTime endDate;

  const LoadSleepStats(this.startDate, this.endDate);

  @override
  List<Object> get props => [startDate, endDate];
}

class LogSleep extends SleepEvent {
  final SleepLog log;

  const LogSleep(this.log);

  @override
  List<Object> get props => [log];
}

class DeleteSleepLog extends SleepEvent {
  final SleepLog log;

  const DeleteSleepLog(this.log);

  @override
  List<Object> get props => [log];
}

class DeleteAllSleepLogsForDate extends SleepEvent {
  final DateTime date;
  const DeleteAllSleepLogsForDate(this.date);

  @override
  List<Object> get props => [date];
}

class DeleteMultipleSleepLogs extends SleepEvent {
  final List<String> logIds;
  final DateTime date;

  const DeleteMultipleSleepLogs(this.logIds, this.date);

  @override
  List<Object> get props => [logIds, date];
}
