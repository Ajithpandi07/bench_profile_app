// lib/features/health_metrics/presentation/bloc/health_metrics_event.dart
import 'package:equatable/equatable.dart';
import 'package:health/health.dart';
import '../../domain/entities/health_metrics.dart';

abstract class HealthMetricsEvent extends Equatable {
  const HealthMetricsEvent();
  @override
  List<Object?> get props => [];
}

/// Basic fetch latest (e.g., last 24h or today depending on usecase)
class GetMetrics extends HealthMetricsEvent {
  final bool forceRefresh;
  const GetMetrics({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

/// Fetch metrics for a single date (day)
class GetMetricsForDate extends HealthMetricsEvent {
  final DateTime date;
  final bool forceRefresh;
  const GetMetricsForDate(this.date, {this.forceRefresh = false});

  @override
  List<Object?> get props => [date, forceRefresh];
}

/// Fetch metrics for a range and optionally filtered by types
class GetMetricsRange extends HealthMetricsEvent {
  final DateTime start;
  final DateTime end;
  final List<HealthDataType>? types;
  final bool forceRefresh;

  const GetMetricsRange({
    required this.start,
    required this.end,
    this.types,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [start, end, types ?? const [], forceRefresh];
}

/// Force a refresh (used by pull-to-refresh)
class RefreshMetrics extends HealthMetricsEvent {
  const RefreshMetrics();
}

/// Load from local cache only (no network/device call)
class LoadCachedMetrics extends HealthMetricsEvent {
  final DateTime? date;
  const LoadCachedMetrics({this.date});

  @override
  List<Object?> get props => [date];
}

/// Persist metrics to local DB (or remote)
class SaveMetrics extends HealthMetricsEvent {
  final List<HealthMetrics> metrics;
  const SaveMetrics(this.metrics);

  @override
  List<Object?> get props => [metrics];
}

class SyncMetrics extends HealthMetricsEvent {
  final int days;
  final DateTime? date;

  const SyncMetrics({this.days = 7, this.date});

  @override
  List<Object?> get props => [days, date];
}

/// Notify progress for sync (UI-friendly)
class SyncProgress extends HealthMetricsEvent {
  final int completed;
  final int total;
  const SyncProgress(this.completed, this.total);

  @override
  List<Object?> get props => [completed, total];
}

/// Sync failed with reason
class SyncFailed extends HealthMetricsEvent {
  final String message;
  const SyncFailed(this.message);

  @override
  List<Object?> get props => [message];
}

/// Mark local metric(s) as synced (after upload)
class MarkMetricsSynced extends HealthMetricsEvent {
  final List<String> uuids; // or ids
  const MarkMetricsSynced(this.uuids);

  @override
  List<Object?> get props => [uuids];
}

/// Request OS permissions (Health, Activity)
class RequestPermissions extends HealthMetricsEvent {
  final List<HealthDataType>? types;
  const RequestPermissions({this.types});

  @override
  List<Object?> get props => [types ?? const []];
}

/// Permission status changed (result from platform)
class PermissionsStatusChanged extends HealthMetricsEvent {
  final bool granted;
  const PermissionsStatusChanged(this.granted);

  @override
  List<Object?> get props => [granted];
}

/// Clear local cache
class ClearCache extends HealthMetricsEvent {
  const ClearCache();
}

class RestoreAllData extends HealthMetricsEvent {
  const RestoreAllData();
}

/// UI: user selected a date via the selector
class SelectDate extends HealthMetricsEvent {
  final DateTime date;
  const SelectDate(this.date);
  @override
  List<Object?> get props => [date];
}

/// UI: toggle metric visibility or group
class ToggleMetricType extends HealthMetricsEvent {
  final String metricKey;
  const ToggleMetricType(this.metricKey);
  @override
  List<Object?> get props => [metricKey];
}

/// Subscribe/unsubscribe to live updates
class SubscribeToLiveUpdates extends HealthMetricsEvent {
  const SubscribeToLiveUpdates();
}

class UnsubscribeFromLiveUpdates extends HealthMetricsEvent {
  const UnsubscribeFromLiveUpdates();
}

class LiveStepUpdate extends HealthMetricsEvent {
  final int delta;
  const LiveStepUpdate(this.delta);

  @override
  List<Object> get props => [delta];
}
