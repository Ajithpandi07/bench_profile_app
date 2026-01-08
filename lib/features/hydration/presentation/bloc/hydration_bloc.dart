import 'package:bloc/bloc.dart';
import '../../domain/domain.dart';
import 'hydration_event.dart';
import 'hydration_state.dart';

class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  final HydrationRepository repository;

  HydrationBloc({required this.repository}) : super(HydrationInitial()) {
    on<LogHydration>(_onLogHydration);
    on<LoadHydrationLogs>(_onLoadHydrationLogs);
    on<LoadHydrationStats>(_onLoadHydrationStats);
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
}
