import 'package:equatable/equatable.dart';
import '../../domain/domain.dart';

abstract class HydrationEvent extends Equatable {
  const HydrationEvent();

  @override
  List<Object> get props => [];
}

class LogHydration extends HydrationEvent {
  final HydrationLog log;

  const LogHydration(this.log);

  @override
  List<Object> get props => [log];
}

class LoadHydrationLogs extends HydrationEvent {
  final DateTime date;
  const LoadHydrationLogs(this.date);

  @override
  List<Object> get props => [date];
}
