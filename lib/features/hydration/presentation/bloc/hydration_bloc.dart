import 'package:bloc/bloc.dart';

import '../../domain/domain.dart';
import 'hydration_event.dart';
import 'hydration_state.dart';
import '../../../auth/domain/repositories/user_profile_repository.dart';

class HydrationBloc extends Bloc<HydrationEvent, HydrationState> {
  final HydrationRepository repository;
  final UserProfileRepository userProfileRepository;

  HydrationBloc({required this.repository, required this.userProfileRepository})
    : super(HydrationInitial()) {
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
    // Always emit loading to ensure UI feedback
    emit(HydrationLoading());
    await Future.delayed(const Duration(milliseconds: 300));

    // Perform deletion
    for (var id in event.logIds) {
      await repository.deleteHydrationLog(id, event.date);
    }

    emit(HydrationDeletedSuccess());

    // Reload logs
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

    // Fetch logs
    final logsResult = await repository.getHydrationLogsForDate(event.date);

    // Fetch profile target
    double? targetWater;
    try {
      final profileResult = await userProfileRepository.getUserProfile();
      profileResult.fold(
        (failure) {
          // ignore: avoid_print
          print('DEBUG: Profile fetch failed: ${failure.message}');
          targetWater = null;
        },
        (profile) {
          final rawTarget = profile.targetWater;
          if (rawTarget != null) {
            // Convert mL to L (e.g. 3000 -> 3.0)
            targetWater = rawTarget / 1000.0;
            // ignore: avoid_print
            print(
              'DEBUG: Fetched targetWater (mL): $rawTarget -> (L): $targetWater',
            );
          }
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('DEBUG: Profile fetch exception: $e');
    }

    logsResult.fold((failure) => emit(HydrationFailure(failure.message)), (
      logs,
    ) {
      emit(HydrationLogsLoaded(logs, event.date, targetWater: targetWater));
    });
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
    final result = await repository.deleteHydrationLog(event.id, event.date);
    result.fold((failure) => emit(HydrationFailure(failure.message)), (_) {
      emit(HydrationDeletedSuccess());
      add(LoadHydrationLogs(event.date));
    });
  }
}
