import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';

import 'package:bench_profile_app/core/error/failures.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../../domain/entities/sleep_log.dart';
import 'sleep_event.dart';
import 'sleep_state.dart';

class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepRepository repository;

  SleepBloc({required this.repository}) : super(SleepInitial()) {
    on<LoadSleepLogs>(_onLoadSleepLogs);
    on<LoadSleepStats>(_onLoadSleepStats);
    on<LogSleep>(_onLogSleep);
    on<DeleteSleepLog>(_onDeleteSleepLog);
    on<DeleteAllSleepLogsForDate>(_onDeleteAllSleepLogsForDate);
    on<DeleteMultipleSleepLogs>(_onDeleteMultipleSleepLogs);
  }

  Future<void> _onDeleteAllSleepLogsForDate(
    DeleteAllSleepLogsForDate event,
    Emitter<SleepState> emit,
  ) async {
    emit(SleepLoading());
    final result = await repository.getSleepLogs(event.date);
    await result.fold(
      (failure) async => emit(SleepError(_mapFailureToMessage(failure))),
      (logs) async {
        for (var log in logs) {
          await repository.deleteSleepLog(log.id, log.endTime);
        }
        add(LoadSleepLogs(event.date));
      },
    );
  }

  Future<void> _onLoadSleepLogs(
    LoadSleepLogs event,
    Emitter<SleepState> emit,
  ) async {
    emit(SleepLoading());
    final result = await repository.getSleepLogs(event.date);
    await result.fold(
      (failure) async => emit(SleepError(_mapFailureToMessage(failure))),
      (logs) async {
        if (logs.isNotEmpty) {
          emit(SleepLoaded(logs));
        } else {
          dev.log(
            '[SleepBloc] No local logs, checking Health Connect',
            name: 'SleepBloc',
          );
          try {
            final hcResult = await repository.fetchSleepFromHealthConnect(
              event.date,
            );
            hcResult.fold(
              (failure) {
                dev.log(
                  '[SleepBloc] HC connect returned failure: $failure',
                  name: 'SleepBloc',
                );
                emit(SleepLoaded(logs));
              },
              (draft) {
                if (draft != null) {
                  dev.log(
                    '[SleepBloc] HC connect returned draft',
                    name: 'SleepBloc',
                  );
                  emit(SleepLoaded(logs, healthConnectDraft: draft));
                } else {
                  dev.log(
                    '[SleepBloc] HC connect returned null',
                    name: 'SleepBloc',
                  );
                  emit(SleepLoaded(logs));
                }
              },
            );
          } catch (e) {
            dev.log('[SleepBloc] HC Exception: $e', name: 'SleepBloc');
            emit(SleepLoaded(logs));
          }
        }
      },
    );
  }

  Future<void> _onLoadSleepStats(
    LoadSleepStats event,
    Emitter<SleepState> emit,
  ) async {
    emit(SleepLoading());
    final result = await repository.getSleepStats(
      event.startDate,
      event.endDate,
    );
    result.fold(
      (failure) => emit(SleepError(_mapFailureToMessage(failure))),
      (logs) => emit(SleepStatsLoaded(logs)),
    );
  }

  Future<void> _onLogSleep(LogSleep event, Emitter<SleepState> emit) async {
    final currentState = state;
    List<SleepLog> contextLogs = [];

    // Use local logs if available to reduce remote reads
    // Ensure we have logs for the relevant period.
    // Since logs are bucketed by EndTime, checking the proposed log's EndTime bucket is critical.
    if (currentState is SleepLoaded &&
        currentState.logs.any(
          (l) =>
              l.endTime.year == event.log.endTime.year &&
              l.endTime.month == event.log.endTime.month &&
              l.endTime.day == event.log.endTime.day,
        )) {
      contextLogs = currentState.logs;
    } else {
      // Fetch for EndTime (primary bucket) and StartTime (potential span bucket)
      final datesToCheck = <DateTime>{
        DateTime(
          event.log.startTime.year,
          event.log.startTime.month,
          event.log.startTime.day,
        ),
        DateTime(
          event.log.endTime.year,
          event.log.endTime.month,
          event.log.endTime.day,
        ),
      };

      for (var date in datesToCheck) {
        final fetchResult = await repository.getSleepLogs(date);
        fetchResult.fold((l) {}, (r) => contextLogs.addAll(r));
      }
    }

    // Validate overlap (allow 24h)
    // Also enforcing: "if log happended 10 p to 1 am mean next entry should be 1AM to 10 PM only"
    // This implies we need to strictly check available gaps.
    if (event.log.duration < const Duration(hours: 24)) {
      // Sort existing logs by start time
      contextLogs.sort((a, b) => a.startTime.compareTo(b.startTime));

      int totalDurationMinutes = 0;
      for (var log in contextLogs) {
        // Exclude the log being edited/updated if IDs match
        if (log.id == event.log.id) continue;

        // Only count logs that belong to the same day bucket (based on endTime)
        if (log.endTime.year == event.log.endTime.year &&
            log.endTime.month == event.log.endTime.month &&
            log.endTime.day == event.log.endTime.day) {
          totalDurationMinutes += log.duration.inMinutes;
        }
      }

      // Check if adding the new log exceeds 24 hours (1440 minutes)
      if (totalDurationMinutes + event.log.duration.inMinutes > 1440) {
        emit(
          const SleepError('Total sleep for the day cannot exceed 24 hours.'),
        );
        return;
      }

      // 1. Check direct overlap
      for (var log in contextLogs) {
        if (log.id == event.log.id) continue;

        final startA = event.log.startTime;
        final endA = event.log.endTime;
        final startB = log.startTime;
        final endB = log.endTime;

        if (startA.isBefore(endB) && endA.isAfter(startB)) {
          emit(
            SleepError(
              'Sleep log overlaps with an existing entry (${DateFormat('h:mm a').format(startB)} - ${DateFormat('h:mm a').format(endB)}).',
            ),
          );
          return;
        }
      }
    }

    emit(SleepLoading());
    final result = await repository.logSleep(
      event.log,
      previousLog: event.previousLog,
    );
    result.fold((failure) => emit(SleepError(_mapFailureToMessage(failure))), (
      _,
    ) {
      emit(SleepOperationSuccess());
    });
  }

  Future<void> _onDeleteSleepLog(
    DeleteSleepLog event,
    Emitter<SleepState> emit,
  ) async {
    emit(SleepLoading());
    final result = await repository.deleteSleepLog(
      event.log.id,
      event.log.endTime,
    );
    result.fold((failure) => emit(SleepError(_mapFailureToMessage(failure))), (
      _,
    ) {
      emit(
        const SleepOperationSuccess(message: 'Sleep log deleted successfully'),
      );
      add(LoadSleepLogs(event.log.endTime));
    });
  }

  Future<void> _onDeleteMultipleSleepLogs(
    DeleteMultipleSleepLogs event,
    Emitter<SleepState> emit,
  ) async {
    emit(SleepLoading());
    // Standardized background delete.
    for (var id in event.logIds) {
      await repository.deleteSleepLog(id, event.date);
    }
    emit(const SleepOperationSuccess(message: 'Sleep logs deleted'));
    add(LoadSleepLogs(event.date));
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Server Failure';
    } else if (failure is NetworkFailure) {
      return 'Network Failure';
    } else {
      return 'Unexpected Error';
    }
  }
}
