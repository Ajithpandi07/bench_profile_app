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
  final SleepLog? healthConnectDraft;

  const SleepLoaded(this.logs, {this.healthConnectDraft});

  @override
  List<Object> get props => [
    logs,
    if (healthConnectDraft != null) healthConnectDraft!,
  ];
}

class SleepStatsLoaded extends SleepState {
  final List<SleepLog> logs;

  const SleepStatsLoaded(this.logs);

  @override
  List<Object> get props => [logs];
}

class SleepOperationSuccess extends SleepState {
  final String? message;

  const SleepOperationSuccess({this.message});

  @override
  List<Object> get props => [if (message != null) message!];
}

class SleepError extends SleepState {
  final String message;

  const SleepError(this.message);

  @override
  List<Object> get props => [message];
}
