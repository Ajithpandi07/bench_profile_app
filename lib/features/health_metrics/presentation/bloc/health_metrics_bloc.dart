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

  Future<void> _onGetMetrics(
      GetMetrics event, Emitter<HealthMetricsState> emit) async {
    final date = DateTime.now(); // Default to today for generic fetch
    emit(HealthMetricsLoading(selectedDate: date));
    final res = await getHealthMetrics.call(NoParams());
    res.fold(
      (failure) {
        if (failure is PermissionFailure) {
          emit(HealthMetricsPermissionRequired(selectedDate: date));
        } else {
          emit(HealthMetricsError(
              message: _mapFailureToMessage(failure), selectedDate: date));
        }
      },
      (maybe) {
        final list = _normalizeToList(maybe);
        final summaryMap = aggregator.aggregate(list);
        final summary = HealthMetricsSummary.fromMap(summaryMap, date);
        emit(HealthMetricsLoaded(
            metrics: list, summary: summary, selectedDate: date));
      },
    );
  }

  Future<void> _onGetMetricsForDate(
      GetMetricsForDate event, Emitter<HealthMetricsState> emit) async {
    // 1. Immediate UI update with Local Data (Source of Truth)
    emit(HealthMetricsLoading(selectedDate: event.date));

    // Fetch local data (fast)
    final localRes = await getHealthMetricsForDate.call(DateParams(event.date));

    localRes.fold(
      (failure) {
        // If local fails, show error, but we still try to sync?
        // Usually if local fails (e.g. database error), we are in trouble.
        if (failure is PermissionFailure) {
          emit(HealthMetricsPermissionRequired(selectedDate: event.date));
        } else {
          emit(HealthMetricsError(
              message: _mapFailureToMessage(failure),
              selectedDate: event.date));
        }
      },
      (maybe) {
        try {
          final list = _normalizeToList(maybe);
          final summaryMap = aggregator.aggregate(list);
          final summary = HealthMetricsSummary.fromMap(summaryMap, event.date);
          emit(HealthMetricsLoaded(
              metrics: list, summary: summary, selectedDate: event.date));
        } catch (e, st) {
          debugPrint('Error processing local metrics: $e\n$st');
          // Non-fatal, might be empty
        }
      },
    );

    // 2. Trigger Background Sync (Device -> Remote -> Local)
    if (repository != null) {
      // optimization: Only sync if date is today or recent past?
      // User asked for "background sync... take health data to remote to locally"
      // We do this blindly for the requested date to ensure freshness.

      // We don't await this to block UI, but we want to update UI when it finishes.
      // So we do await it, but since we already emitted Loaded above, the UI is interactive.
      // However, bloc handlers sort of queue. To truly be "background" to the UI,
      // we must rely on the fact that we emitted state above.
      // BUT: Bloc processes events sequentially. Awaiting here delayed processing next event?
      // No, strictly awaiting here keeps this handler active.
      // If user taps another date, that event queues.
      // To make it truly non-blocking for OTHER events (like fast date switching),
      // we should maybe spawn a separate Future or use a "Sync" event?
      // But standard Bloc pattern: if we await, we block the stream.
      // Solution: We emitted Loaded. That's good. But if user clicks next date,
      // we are stuck awaiting sync here.
      // Better approach: Fire a separate SyncMetrics event!
      add(SyncMetrics(date: event.date));
    }
  }

  Future<void> _onGetMetricsRange(
      GetMetricsRange event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsLoading(selectedDate: state.selectedDate));
    // Prefer repository method for ranges if available
    if (repository != null) {
      final res = await repository!
          .getHealthMetricsRange(event.start, event.end, event.types ?? []);
      res.fold(
        (failure) => emit(HealthMetricsError(
            message: _mapFailureToMessage(failure),
            selectedDate: state.selectedDate)),
        (list) {
          emit(HealthMetricsLoaded(
              metrics: list, summary: null, selectedDate: state.selectedDate));
        },
      );
      return;
    }
    emit(HealthMetricsError(
        message: 'Range queries are not implemented (repository missing)',
        selectedDate: state.selectedDate));
  }

  Future<void> _onRefresh(
      RefreshMetrics event, Emitter<HealthMetricsState> emit) async {
    // Refresh the currently selected date
    add(GetMetricsForDate(state.selectedDate));
  }

  Future<void> _onLoadCached(
      LoadCachedMetrics event, Emitter<HealthMetricsState> emit) async {
    final date = event.date ?? DateTime.now();
    if (repository == null) {
      emit(HealthMetricsError(
          message: 'Local cache not available', selectedDate: date));
      return;
    }
    final res = await repository!.getHealthMetricsForDate(date);
    // repository returns Either<Failure, HealthMetrics> or list depending on impl — normalize
    res.fold(
      (failure) => emit(HealthMetricsError(
          message: _mapFailureToMessage(failure), selectedDate: date)),
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

  Future<void> _onSaveMetrics(
      SaveMetrics event, Emitter<HealthMetricsState> emit) async {
    if (repository == null) {
      emit(HealthMetricsError(
          message: 'Repository not available to save metrics',
          selectedDate: state.selectedDate));
      return;
    }

    final res = await repository!.saveHealthMetrics(
        'local', event.metrics); // TODO: pass real uid if available
    res.fold(
      (failure) => emit(HealthMetricsError(
          message: _mapFailureToMessage(failure),
          selectedDate: state.selectedDate)),
      (_) => emit(HealthMetricsLoaded(
          metrics: event.metrics,
          summary: HealthMetricsSummary.fromMap(
              aggregator.aggregate(event.metrics), DateTime.now()),
          selectedDate: state.selectedDate)),
    );
  }

  Future<void> _onSyncMetrics(
      SyncMetrics event, Emitter<HealthMetricsState> emit) async {
    // This handler runs after GetMetricsForDate because we added it to queue.
    // It will process in background relative to the initial UI load.

    final date = event.date ?? state.selectedDate;

    if (repository == null) return;

    // Use specific syncForDate if it exists in repository, otherwise fallback to "SyncManager" (old way)
    // The user wants "sync for the date".

    // emit(HealthMetricsSyncing(...)); // Optional: show spinner? User said "background", maybe no spinner.

    final res = await repository!.syncMetricsForDate(date);

    await res.fold(
      (failure) async {
        if (failure is PermissionFailure) {
          emit(HealthMetricsPermissionRequired(selectedDate: date));
        } else if (failure is HealthConnectFailure) {
          emit(HealthMetricsHealthConnectRequired(selectedDate: date));
        }
        // Log failure but don't disrupt UI if local data was okay
        debugPrint('Background sync failed: $failure');
      },
      (_) async {
        // Success! Re-fetch local data to update UI with fresh inputs
        // We can reuse the same UC or call repo directly.
        // Let's reuse the internal logic we put in _onGetMetricsForDate but without triggering another sync loop.
        // Or simply emit a new Loaded state manually.
        final localRes = await getHealthMetricsForDate.call(DateParams(date));
        localRes.fold((f) => null, // ignore
            (maybe) {
          final list = _normalizeToList(maybe);
          final summaryMap = aggregator.aggregate(list);
          final summary = HealthMetricsSummary.fromMap(summaryMap, date);
          // Verify if user is still on this date?
          if (state.selectedDate == date) {
            emit(HealthMetricsLoaded(
                metrics: list, summary: summary, selectedDate: date));
          }
        });
      },
    );
  }

  Future<void> _onSyncProgress(
      SyncProgress event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsSyncing(
        completed: event.completed,
        total: event.total,
        selectedDate: state.selectedDate));
  }

  Future<void> _onSyncFailed(
      SyncFailed event, Emitter<HealthMetricsState> emit) async {
    emit(HealthMetricsError(
        message: event.message, selectedDate: state.selectedDate));
  }

  Future<void> _onMarkMetricsSynced(
      MarkMetricsSynced event, Emitter<HealthMetricsState> emit) async {
    // If your repository supports marking entries as synced, call it here.
    // Default: do nothing and just refresh.
    add(const RefreshMetrics());
  }

  Future<void> _onRequestPermissions(
      RequestPermissions event, Emitter<HealthMetricsState> emit) async {
    // Permission handling is platform-specific and likely belongs in DataSource.
    // This event is a signal for the UI. You can call a "permission helper" here if you have one.
    emit(HealthMetricsPermissionRequired(selectedDate: state.selectedDate));
  }

  Future<void> _onPermissionsStatusChanged(
      PermissionsStatusChanged event, Emitter<HealthMetricsState> emit) async {
    if (event.granted) {
      add(const RefreshMetrics());
    } else {
      emit(HealthMetricsPermissionRequired(selectedDate: state.selectedDate));
    }
  }

  Future<void> _onClearCache(
      ClearCache event, Emitter<HealthMetricsState> emit) async {
    if (repository == null) {
      emit(HealthMetricsError(
          message: 'Repository not available',
          selectedDate: state.selectedDate));
      return;
    }
    try {
      await repository!
          .saveHealthMetrics('local', <HealthMetrics>[]); // no-op placeholder
      emit(HealthMetricsEmpty(selectedDate: state.selectedDate));
    } catch (e) {
      emit(HealthMetricsError(
          message: e.toString(), selectedDate: state.selectedDate));
    }
  }

  Future<void> _onSelectDate(
      SelectDate event, Emitter<HealthMetricsState> emit) async {
    // UI helper - fetch for date and update state
    add(GetMetricsForDate(event.date));
  }

  Future<void> _onToggleMetricType(
      ToggleMetricType event, Emitter<HealthMetricsState> emit) async {
    // TODO: Implement logic to toggle visibility of specific metric types in the UI.
    // This might require updating the HealthMetricsState to include a filter or visibility map.
  }

  Future<void> _onSubscribeToLiveUpdates(
      SubscribeToLiveUpdates event, Emitter<HealthMetricsState> emit) async {
    // TODO: Implement subscription to real-time health data updates from the repository.
    // This requires the repository to expose a Stream<List<HealthMetrics>>.
  }

  Future<void> _onUnsubscribeFromLiveUpdates(UnsubscribeFromLiveUpdates event,
      Emitter<HealthMetricsState> emit) async {
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
