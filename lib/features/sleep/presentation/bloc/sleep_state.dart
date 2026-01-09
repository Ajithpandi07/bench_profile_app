import 'package:equatable/equatable.dart';
import '../../domain/entities/sleep_log.dart';

abstract class SleepState extends Equatable {
  const SleepState();

  @override
  List<Object> get props => [];
}

class SleepInitial extends SleepState {}

class SleepLoading extends SleepState {}

class SleepLoaded extends SleepState {
  final List<SleepLog> logs;

  const SleepLoaded(this.logs);

  @override
  List<Object> get props => [logs];
}

class SleepStatsLoaded extends SleepState {
  final List<SleepLog> logs;

  const SleepStatsLoaded(this.logs);

  @override
  List<Object> get props => [logs];
}

class SleepOperationSuccess extends SleepState {}

class SleepError extends SleepState {
  final String message;

  const SleepError(this.message);

  @override
  List<Object> get props => [message];
}
