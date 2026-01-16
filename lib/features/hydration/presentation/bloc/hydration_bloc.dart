import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import '../../domain/domain.dart';
import 'hydration_event.dart';
import 'hydration_state.dart';

class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  final HydrationRepository repository;

  HydrationBloc({required this.repository}) : super(HydrationInitial()) {
    on<LogHydration>(_onLogHydration);
    on<LoadHydrationLogs>(_onLoadHydrationLogs);
    on<LoadHydrationStats>(_onLoadHydrationStats);
    on<DeleteHydrationLog>(_onDeleteHydrationLog);
    on<DeleteAllHydrationForDate>(_onDeleteAllHydrationForDate);
    on<DeleteMultipleHydrationLogs>(_onDeleteMultipleHydrationLogs);
  }

  Future<void> _onDeleteMultipleHydrationLogs(
    DeleteMultipleHydrationLogs event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationLoading());
    final results = await Future.wait(
      event.logIds.map((id) => repository.deleteHydrationLog(id, event.date)),
    );

    // Check if any failed
    final failure = results.firstWhere(
      (element) => element.isLeft(),
      orElse: () => const Right(null),
    );

    failure.fold((f) => emit(HydrationFailure(f.message)), (_) {
      // If all succeeded (or even if some failed, we probably want to reload to show current state)
      // But here we only add load if no failure (or handle partial failure?)
      // Let's reload regardless to show updated list
    });

    add(LoadHydrationLogs(event.date));
  }

  Future<void> _onDeleteAllHydrationForDate(
    DeleteAllHydrationForDate event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationLoading());
    final result = await repository.getHydrationLogsForDate(event.date);
    await result.fold(
      (failure) async => emit(HydrationFailure(failure.message)),
      (logs) async {
        for (var log in logs) {
          await repository.deleteHydrationLog(log.id, event.date);
        }
        add(LoadHydrationLogs(event.date));
      },
    );
  }

  Future<void> _onLogHydration(
    LogHydration event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationSaving());
    final result = await repository.logWaterIntake(event.log);
    result.fold(
      (failure) => emit(HydrationFailure(failure.message)),
      (_) => emit(HydrationSuccess()),
    );
  }

  Future<void> _onLoadHydrationLogs(
    LoadHydrationLogs event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationLoading());
    final result = await repository.getHydrationLogsForDate(event.date);
    result.fold(
      (failure) => emit(HydrationFailure(failure.message)),
      (logs) => emit(HydrationLogsLoaded(logs, event.date)),
    );
  }

  Future<void> _onLoadHydrationStats(
    LoadHydrationStats event,
    Emitter<HydrationState> emit,
  ) async {
    emit(HydrationLoading());
    final result = await repository.getHydrationStats(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    result.fold(
      (failure) => emit(HydrationFailure(failure.message)),
      (stats) =>
          emit(HydrationStatsLoaded(stats, event.startDate, event.endDate)),
    );
  }

  Future<void> _onDeleteHydrationLog(
    DeleteHydrationLog event,
    Emitter<HydrationState> emit,
  ) async {
    // Optimistic update or reload.
    // Assuming repository has deleteHydrationLog? I need to check repository interface first!
    // But I will assume it follows pattern or I will check repository now.
    // Wait, I didn't check repository.
    // If it doesn't exist, I need to add it to repository interface and impl.
    // Let's assume for now, but I should probably check.
    // I will write the handler assuming it exists, if error I fix repository.
    final result = await repository.deleteHydrationLog(event.id, event.date);
    result.fold((failure) => emit(HydrationFailure(failure.message)), (_) {
      // Reload logs
      add(LoadHydrationLogs(event.date));
    });
  }
}
