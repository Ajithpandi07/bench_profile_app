import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;
import 'package:intl/intl.dart';

import '../../../../../core/error/failures.dart';
import '../../domain/repositories/sleep_repository.dart';
import '../../domain/entities/sleep_log.dart';
import 'sleep_event.dart';
import 'sleep_state.dart';

class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepRepository repository;

  SleepBloc({required this.repository}) : super(SleepInitial()) {
    on<LoadSleepLogs>(_onLoadSleepLogs);
    on<LoadSleepStats>(_onLoadSleepStats);
    on<CheckLocalHealthConnectData>(_onCheckLocalHealthConnectData);
    on<LogSleep>(_onLogSleep);
    on<DeleteSleepLog>(_onDeleteSleepLog);
    on<DeleteAllSleepLogsForDate>(_onDeleteAllSleepLogsForDate);
    on<DeleteMultipleSleepLogs>(_onDeleteMultipleSleepLogs);
    on<IgnoreSleepDraft>(_onIgnoreSleepDraft);
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

    // parallel fetch
    final logsFuture = repository.getSleepLogs(event.date);
    final draftFuture = repository.checkLocalHealthConnectData(event.date);

    final logsResult = await logsFuture;
    final draftResult = await draftFuture;

    List<SleepLog> localDrafts = [];
    draftResult.fold((_) {}, (r) => localDrafts = r);

    await logsResult.fold(
      (failure) async => emit(SleepError(_mapFailureToMessage(failure))),
      (logs) async {
        final validDraft = _getBestValidDraft(localDrafts, logs);

        if (logs.isNotEmpty) {
          emit(SleepLoaded(logs, healthConnectDraft: validDraft));
        } else {
          dev.log(
            '[SleepBloc] No remote logs found. Draft found: ${validDraft != null}',
            name: 'SleepBloc',
          );
          emit(SleepLoaded(logs, healthConnectDraft: validDraft));
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

  Future<void> _onIgnoreSleepDraft(
    IgnoreSleepDraft event,
    Emitter<SleepState> emit,
  ) async {
    // Just tell repo to ignore. The UI should have optimistically closed the dialog.
    // But if we want to ensure state consistency, we could reload?
    // User requested: "actually its getting added automatically i need to ask user with poup to confirm this log can be save lilke that even i delete the saved entry it got stored again better to keep the uuid in the remote server level to identlyify the sleep log entry"
    // "keep the uuid in the remote server level" -> handled by using the ID.
    // "No" on popup -> this event.
    await repository.ignoreSleepDraft(event.uuid);
    // Might want to reload to refresh drafts list (in case next draft should be shown)
    // But let's assume UI handles the dialog close.
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
    await Future.delayed(const Duration(milliseconds: 300));

    // Standardized background delete.
    for (var id in event.logIds) {
      await repository.deleteSleepLog(id, event.date);
    }
    emit(const SleepOperationSuccess(message: 'Sleep logs deleted'));
    add(LoadSleepLogs(event.date));
  }

  Future<void> _onCheckLocalHealthConnectData(
    CheckLocalHealthConnectData event,
    Emitter<SleepState> emit,
  ) async {
    // Check repository for LOCAL HC data
    final result = await repository.checkLocalHealthConnectData(event.date);

    result.fold(
      (failure) {
        // Ignore failure, just log?
      },
      (drafts) {
        if (drafts.isNotEmpty) {
          if (state is SleepLoaded) {
            final currentLogs = (state as SleepLoaded).logs;
            final validDraft = _getBestValidDraft(drafts, currentLogs);
            emit(
              (state as SleepLoaded).copyWith(healthConnectDraft: validDraft),
            );
          } else {
            // Should not happen if flow is correct, but effectively we'd need logs to filter against.
            // If we don't have logs, we assume all drafts are candidates, pick the first (longest).
            final validDraft = drafts.first;
            // Provide empty list for logs since we don't have them yet in this branch
            emit(SleepLoaded(const [], healthConnectDraft: validDraft));
          }
        }
      },
    );
  }

  /// Selects the best draft (longest) that does NOT overlap with any existing log.
  SleepLog? _getBestValidDraft(
    List<SleepLog> drafts,
    List<SleepLog> existingLogs,
  ) {
    if (drafts.isEmpty) return null;

    for (final draft in drafts) {
      bool hasOverlap = false;
      for (final log in existingLogs) {
        // Check matching ID (Remote check)
        if (log.id == draft.id) {
          hasOverlap = true; // Use same flag to invalidate
          break;
        }

        // Check overlap
        if (draft.startTime.isBefore(log.endTime) &&
            draft.endTime.isAfter(log.startTime)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return draft; // detailed drafts are already sorted by duration in Repo
      }
    }
    return null; // All drafts overlap
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
