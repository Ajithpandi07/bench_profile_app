// lib/features/health_metrics/presentation/bloc/health_metrics_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class HealthMetricsState extends Equatable {
  final DateTime selectedDate;
  const HealthMetricsState({required this.selectedDate});

  @override
  List<Object?> get props => [selectedDate];
}

class HealthMetricsEmpty extends HealthMetricsState {
  const HealthMetricsEmpty({required super.selectedDate});
}

class HealthMetricsLoading extends HealthMetricsState {
  const HealthMetricsLoading({required super.selectedDate});
}

/// Generic loaded state — contains raw list and optional aggregated summary
class HealthMetricsLoaded extends HealthMetricsState {
  final List<HealthMetrics> metrics;
  final HealthMetricsSummary? summary;
  final bool isSyncing;

  const HealthMetricsLoaded({
    required this.metrics,
    this.summary,
    this.isSyncing = false,
    required super.selectedDate,
  });

  @override
  List<Object?> get props => [metrics, summary, selectedDate, isSyncing];
}

class HealthMetricsError extends HealthMetricsState {
  final String message;
  const HealthMetricsError(
      {required this.message, required super.selectedDate});

  @override
  List<Object?> get props => [message, selectedDate];
}

/// Used during long running background sync operations
class HealthMetricsSyncing extends HealthMetricsState {
  final int completed;
  final int total;
  const HealthMetricsSyncing({
    required this.completed,
    required this.total,
    required super.selectedDate,
  });

  @override
  List<Object?> get props => [completed, total, selectedDate];
}

/// Permission required state
class HealthMetricsPermissionRequired extends HealthMetricsState {
  final String reason;
  const HealthMetricsPermissionRequired({
    this.reason = 'Permissions required',
    required super.selectedDate,
  });

  @override
  List<Object?> get props => [reason, selectedDate];
}

class HealthMetricsHealthConnectRequired extends HealthMetricsState {
  const HealthMetricsHealthConnectRequired({required super.selectedDate});
}

/// Cache-only loaded
class HealthMetricsCachedLoaded extends HealthMetricsState {
  final List<HealthMetrics> metrics;
  const HealthMetricsCachedLoaded({
    required this.metrics,
    required super.selectedDate,
  });

  @override
  List<Object?> get props => [metrics, selectedDate];
}
