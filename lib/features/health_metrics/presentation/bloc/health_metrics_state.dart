import 'package:equatable/equatable.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';

abstract class HealthMetricsState extends Equatable {
  const HealthMetricsState();

  @override
  List<Object> get props => [];
}

class HealthMetricsEmpty extends HealthMetricsState {}

class HealthMetricsLoading extends HealthMetricsState {}

class HealthMetricsLoaded extends HealthMetricsState {
  final HealthMetricsSummary metrics;

  const HealthMetricsLoaded({required this.metrics});

  @override
  List<Object> get props => [metrics];
}

class HealthMetricsError extends HealthMetricsState {
  final String message;

  const HealthMetricsError({required this.message});

  @override
  List<Object> get props => [message];
}