// health_metrics_event.dart
import 'package:equatable/equatable.dart';

abstract class HealthMetricsEvent extends Equatable {
  const HealthMetricsEvent();

  @override
  List<Object?> get props => [];
}

class GetMetrics extends HealthMetricsEvent {}

class GetMetricsForDate extends HealthMetricsEvent {
  final DateTime date;
  GetMetricsForDate(this.date);
}
