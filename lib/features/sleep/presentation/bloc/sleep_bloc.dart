import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as dev;

import 'package:bench_profile_app/core/error/failures.dart';
import '../../domain/repositories/sleep_repository.dart';
import 'sleep_event.dart';
import 'sleep_state.dart';

class SleepBloc extends Bloc<SleepEvent, SleepState> {
  final SleepRepository repository;

  SleepBloc({required this.repository}) : super(SleepInitial()) {
    on<LoadSleepLogs>(_onLoadSleepLogs);
    on<LoadSleepStats>(_onLoadSleepStats);
    on<LogSleep>(_onLogSleep);
    on<DeleteSleepLog>(_onDeleteSleepLog);
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
    emit(SleepLoading());
    final result = await repository.logSleep(event.log);
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
    final result = await repository.deleteSleepLog(event.log);
    result.fold(
      (failure) => emit(SleepError(_mapFailureToMessage(failure))),
      (_) => emit(SleepOperationSuccess()),
    );
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
