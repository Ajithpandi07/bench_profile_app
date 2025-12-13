// lib/features/health_metrics/presentation/bloc/health_metrics_bloc.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:bench_profile_app/core/util/metric_aggregator.dart';
import 'package:bench_profile_app/core/usecase/usecase.dart' hide DateParams;
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/usecases/get_health_metrics_for_date.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics.dart';
import 'package:bench_profile_app/features/health_metrics/domain/entities/health_metrics_summary.dart';
import 'package:bench_profile_app/features/health_metrics/domain/repositories/health_repository.dart';
import 'health_metrics_event.dart';
import 'health_metrics_state.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:dartz/dartz.dart';

/// Optional SyncManager interface - implement and register in DI if you want
/// background sync capabilities. The bloc will call performSyncOnce(days).
abstract class SyncManager {
  Future<Either<Failure, void>> performSyncOnce({int days});
}

class HealthMetricsBloc extends Bloc<HealthMetricsEvent, HealthMetricsState> {
  final GetHealthMetrics getHealthMetrics;
  final GetHealthMetricsForDate getHealthMetricsForDate;
  final MetricAggregator aggregator;
  final HealthRepository? repository;
  final SyncManager? syncManager;
  StreamSubscription? _updatesSubscription;

  HealthMetricsBloc({
    required this.getHealthMetrics,
    required this.getHealthMetricsForDate,
    required this.aggregator,
    this.repository,
    this.syncManager,
  }) : super(HealthMetricsEmpty(selectedDate: DateTime.now())) {
    on<GetMetrics>(_onGetMetrics);
    on<GetMetricsForDate>(_onGetMetricsForDate);
    on<GetMetricsRange>(_onGetMetricsRange);
    on<RefreshMetrics>(_onRefresh);
    on<LoadCachedMetrics>(_onLoadCached);
    on<SaveMetrics>(_onSaveMetrics);
    on<SyncMetrics>(_onSyncMetrics);
    on<SyncProgress>(_onSyncProgress);
    on<SyncFailed>(_onSyncFailed);
    on<MarkMetricsSynced>(_onMarkMetricsSynced);
    on<RequestPermissions>(_onRequestPermissions);
    on<PermissionsStatusChanged>(_onPermissionsStatusChanged);
    on<ClearCache>(_onClearCache);
    on<SelectDate>(_onSelectDate);
    on<ToggleMetricType>(_onToggleMetricType);
    on<SubscribeToLiveUpdates>(_onSubscribeToLiveUpdates);
    on<UnsubscribeFromLiveUpdates>(_onUnsubscribeFromLiveUpdates);
  }

  // Helper: normalize various possible return types into List<HealthMetrics>.
  List<HealthMetrics> _normalizeToList(dynamic maybe) {
    if (maybe == null) return <HealthMetrics>[];
    if (maybe is List<HealthMetrics>) return maybe;
    if (maybe is HealthMetrics) return <HealthMetrics>[maybe];
    if (maybe is List) {
      try {
        return (maybe as List).cast<HealthMetrics>();
      } catch (_) {
        return <HealthMetrics>[];
      }
    }
    return <HealthMetrics>[];
  }

  Future<void> _onGetMetrics(GetMetrics event, Emitter<HealthMetricsState> emit) async {
    final date = DateTime.now(); // Default to today for generic fetch
    emit(HealthMetricsLoading(selectedDate: date));
    final res = await getHealthMetrics.call(NoParams());
    res.fold(
      (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: date)),
      (maybe) {
        final list = _normalizeToList(maybe);
        final summaryMap = aggregator.aggregate(list);
        final summary = HealthMetricsSummary.fromMap(summaryMap, date);
        emit(HealthMetricsLoaded(metrics: list, summary: summary, selectedDate: date));
      },
    );
  }

  Future<void> _onGetMetricsForDate(GetMetricsForDate event, Emitter<HealthMetricsState> emit) async {
    // Update date immediately
    emit(HealthMetricsLoading(selectedDate: event.date));
    final res = await getHealthMetricsForDate.call(DateParams(event.date));
    res.fold(
      (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: event.date)),
      (maybe) {
        try {
          final list = _normalizeToList(maybe);
          final summaryMap = aggregator.aggregate(list);
          final summary = HealthMetricsSummary.fromMap(summaryMap, event.date);
          emit(HealthMetricsLoaded(metrics: list, summary: summary, selectedDate: event.date));
        } catch (e, st) {
          debugPrint('Error processing metrics: $e\n$st');
          emit(HealthMetricsError(message: 'Failed to process data: $e', selectedDate: event.date));
        }
      },
    );
  }

  Future<void> _onGetMetricsRange(GetMetricsRange event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsLoading(selectedDate: state.selectedDate));
    // Prefer repository method for ranges if available
    if (repository != null) {
      final res = await repository!.getHealthMetricsRange(event.start, event.end, event.types ?? []);
      res.fold(
        (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: state.selectedDate)),
        (list) {
          emit(HealthMetricsLoaded(metrics: list, summary: null, selectedDate: state.selectedDate));
        },
      );
      return;
    }
    emit(HealthMetricsError(message: 'Range queries are not implemented (repository missing)', selectedDate: state.selectedDate));
  }

  Future<void> _onRefresh(RefreshMetrics event, Emitter<HealthMetricsState> emit) async {
    // Refresh the currently selected date
    add(GetMetricsForDate(state.selectedDate));
  }

  Future<void> _onLoadCached(LoadCachedMetrics event, Emitter<HealthMetricsState> emit) async {
    final date = event.date ?? DateTime.now();
    if (repository == null) {
      emit(HealthMetricsError(message: 'Local cache not available', selectedDate: date));
      return;
    }
    final res = await repository!.getHealthMetricsForDate(date);
    // repository returns Either<Failure, HealthMetrics> or list depending on impl — normalize
    res.fold(
      (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: date)),
      (maybe) {
        // maybe is HealthMetrics OR List<HealthMetrics> depending on impl
        final list = _normalizeToList(maybe);
        if (list.isEmpty) {
          emit(HealthMetricsEmpty(selectedDate: date));
        } else {
          emit(HealthMetricsCachedLoaded(metrics: list, selectedDate: date));
        }
      },
    );
  }

  Future<void> _onSaveMetrics(SaveMetrics event, Emitter<HealthMetricsState> emit) async {
    if (repository == null) {
      emit(HealthMetricsError(message: 'Repository not available to save metrics', selectedDate: state.selectedDate));
      return;
    }

    final res = await repository!.saveHealthMetrics('local', event.metrics); // TODO: pass real uid if available
    res.fold(
      (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: state.selectedDate)),
      (_) => emit(HealthMetricsLoaded(metrics: event.metrics, summary: HealthMetricsSummary.fromMap(aggregator.aggregate(event.metrics), DateTime.now()), selectedDate: state.selectedDate)),
    );
  }

  Future<void> _onSyncMetrics(SyncMetrics event, Emitter<HealthMetricsState> emit) async {
    if (syncManager == null) {
      emit(HealthMetricsError(message: 'SyncManager not configured. Register SyncManager in DI to enable background sync.', selectedDate: state.selectedDate));
      return;
    }

    emit(HealthMetricsSyncing(completed: 0, total: 0, selectedDate: state.selectedDate));
    final res = await syncManager!.performSyncOnce(days: event.days);
    res.fold(
      (failure) => emit(HealthMetricsError(message: _mapFailureToMessage(failure), selectedDate: state.selectedDate)),
      (_) => add(const RefreshMetrics()),
    );
  }

  Future<void> _onSyncProgress(SyncProgress event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsSyncing(completed: event.completed, total: event.total, selectedDate: state.selectedDate));
  }

  Future<void> _onSyncFailed(SyncFailed event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsError(message: event.message, selectedDate: state.selectedDate));
  }

  Future<void> _onMarkMetricsSynced(MarkMetricsSynced event, Emitter<HealthMetricsState> emit) async {
    // If your repository supports marking entries as synced, call it here.
    // Default: do nothing and just refresh.
    add(const RefreshMetrics());
  }

  Future<void> _onRequestPermissions(RequestPermissions event, Emitter<HealthMetricsState> emit) async {
    // Permission handling is platform-specific and likely belongs in DataSource.
    // This event is a signal for the UI. You can call a "permission helper" here if you have one.
    emit(HealthMetricsPermissionRequired(selectedDate: state.selectedDate));
  }

  Future<void> _onPermissionsStatusChanged(PermissionsStatusChanged event, Emitter<HealthMetricsState> emit) async {
    if (event.granted) {
      add(const RefreshMetrics());
    } else {
      emit(HealthMetricsPermissionRequired(selectedDate: state.selectedDate));
    }
  }

  Future<void> _onClearCache(ClearCache event, Emitter<HealthMetricsState> emit) async {
    if (repository == null) {
      emit(HealthMetricsError(message: 'Repository not available', selectedDate: state.selectedDate));
      return;
    }
    try {
      await repository!.saveHealthMetrics('local', <HealthMetrics>[]); // no-op placeholder
      emit(HealthMetricsEmpty(selectedDate: state.selectedDate));
    } catch (e) {
      emit(HealthMetricsError(message: e.toString(), selectedDate: state.selectedDate));
    }
  }

  Future<void> _onSelectDate(SelectDate event, Emitter<HealthMetricsState> emit) async {
    // UI helper - fetch for date and update state
    add(GetMetricsForDate(event.date));
  }

  Future<void> _onToggleMetricType(ToggleMetricType event, Emitter<HealthMetricsState> emit) async {
    // TODO: Implement logic to toggle visibility of specific metric types in the UI.
    // This might require updating the HealthMetricsState to include a filter or visibility map.
  }

  Future<void> _onSubscribeToLiveUpdates(SubscribeToLiveUpdates event, Emitter<HealthMetricsState> emit) async {
    // TODO: Implement subscription to real-time health data updates from the repository.
    // This requires the repository to expose a Stream<List<HealthMetrics>>.
  }

  Future<void> _onUnsubscribeFromLiveUpdates(UnsubscribeFromLiveUpdates event, Emitter<HealthMetricsState> emit) async {
    await _updatesSubscription?.cancel();
    _updatesSubscription = null;
  }

  @override
  Future<void> close() {
    _updatesSubscription?.cancel();
    return super.close();
  }

  // Helper to map Failure -> user message
  String _mapFailureToMessage(dynamic failure) {
    if (failure is Failure) return failure.message;
    return failure?.toString() ?? 'Unexpected error';
  }
}
