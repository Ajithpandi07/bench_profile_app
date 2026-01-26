import 'package:bloc/bloc.dart';
import '../../domain/repositories/activity_repository.dart';
import 'activity_event.dart';
import 'activity_state.dart';

class ActivityBloc extends Bloc<ActivityEvent, ActivityState> {
  final ActivityRepository repository;

  ActivityBloc({required this.repository}) : super(ActivityInitial()) {
    on<LoadActivitiesForDate>(_onLoadActivities);
    on<AddActivityEvent>(_onAddActivity);
    on<UpdateActivityEvent>(_onUpdateActivity);
    on<DeleteActivityEvent>(_onDeleteActivity);
    on<DeleteMultipleActivities>(_onDeleteMultipleActivities);
    on<LoadActivityStats>(_onLoadActivityStats);
  }

  Future<void> _onLoadActivityStats(
    LoadActivityStats event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    final now = DateTime.now();
    final start = event.start ?? DateTime(now.year - 1, now.month, now.day);
    final end = event.end ?? DateTime(now.year + 1, 12, 31);

    final result = await repository.getDailySummaries(start, end);
    result.fold(
      (failure) => emit(ActivityOperationFailure(failure.message)),
      (summaries) => emit(ActivityStatsLoaded(summaries)),
    );
  }

  Future<void> _onDeleteMultipleActivities(
    DeleteMultipleActivities event,
    Emitter<ActivityState> emit,
  ) async {
    // Emit Loading to show progress/shimmer
    emit(ActivityLoading());
    await Future.delayed(const Duration(milliseconds: 300));

    await Future.wait(
      event.activityIds.map((id) => repository.deleteActivity(id, event.date)),
    );

    emit(const ActivityOperationSuccess('Activities deleted'));
    add(LoadActivitiesForDate(event.date));
  }

  Future<void> _onLoadActivities(
    LoadActivitiesForDate event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    // Assuming userId is handled by repository internally via Auth
    final result = await repository.getActivitiesForDate('', event.date);
    result.fold(
      (failure) => emit(ActivityOperationFailure(failure.message)),
      (activities) => emit(ActivitiesLoaded(activities, event.date)),
    );
  }

  Future<void> _onAddActivity(
    AddActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    final result = await repository.addActivity(event.activity);
    result.fold((failure) => emit(ActivityOperationFailure(failure.message)), (
      _,
    ) {
      emit(const ActivityOperationSuccess('Activity added successfully'));
      add(LoadActivitiesForDate(event.activity.startTime));
    });
  }

  Future<void> _onUpdateActivity(
    UpdateActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    emit(ActivityLoading());
    final result = await repository.updateActivity(event.activity);
    result.fold((failure) => emit(ActivityOperationFailure(failure.message)), (
      _,
    ) {
      emit(const ActivityOperationSuccess('Activity updated successfully'));
      add(LoadActivitiesForDate(event.activity.startTime));
    });
  }

  Future<void> _onDeleteActivity(
    DeleteActivityEvent event,
    Emitter<ActivityState> emit,
  ) async {
    // We don't necessarily emit loading here to avoid screen flicker if it's a small action,
    // but for safety/feedback we can. Or we can rely on a specific deletion state.
    // For now, let's just do it and reload.
    final result = await repository.deleteActivity(
      event.activityId,
      event.date,
    );
    result.fold((failure) => emit(ActivityOperationFailure(failure.message)), (
      _,
    ) {
      // We could emit success, but usually we just reload the list.
      // If we emit Success, the UI might show a snackbar.
      emit(const ActivityOperationSuccess('Activity deleted'));
      add(LoadActivitiesForDate(event.date));
    });
  }
}
