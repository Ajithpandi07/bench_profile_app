import 'package:equatable/equatable.dart';
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

class HydrationLogsLoaded extends HydrationState {
  final List<HydrationLog> logs;
  final DateTime date;

  const HydrationLogsLoaded(this.logs, this.date);

  @override
  List<Object> get props => [logs, date];
}

class HydrationFailure extends HydrationState {
  final String message;

  const HydrationFailure(this.message);

  @override
  List<Object> get props => [message];
}
