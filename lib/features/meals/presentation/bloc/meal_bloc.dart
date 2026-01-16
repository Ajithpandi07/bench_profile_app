import 'package:bloc/bloc.dart';
import '../../domain/repositories/meal_repository.dart';
import 'meal_event.dart';
import 'meal_state.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/user_meal.dart';

class MealBloc extends Bloc<MealEvent, MealState> {
  final MealRepository repository;

  MealBloc({required this.repository}) : super(MealInitial()) {
    on<LoadMealsForDate>(_onLoadMeals);
    on<LogMealEvent>(_onLogMeal);
    on<AddUserMeal>(_onAddUserMeal);
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadUserLibrary>(_onLoadUserLibrary); // Added
    on<AddUserFood>(_onAddUserFood);
    on<SearchFoodEvent>(_onSearchFood);
    on<ReplaceMealLogEvent>(_onReplaceMealLog);
    on<DeleteMealLog>(_onDeleteMealLog);
    on<DeleteAllMealsForDate>(_onDeleteAllMealsForDate);
    on<DeleteMultipleMeals>(_onDeleteMultipleMeals);
  }

  Future<void> _onDeleteMultipleMeals(
    DeleteMultipleMeals event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    // Iterate and delete. Ideally, repository should support bulk delete,
    // but we'll iterate for now as per previous pattern.
    for (final id in event.mealLogIds) {
      await repository.deleteMealLog(id, event.date);
    }
    add(LoadMealsForDate(event.date));
  }

  Future<void> _onDeleteAllMealsForDate(
    DeleteAllMealsForDate event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    final result = await repository.getMealsForDate(event.date);
    await result.fold(
      (failure) async => emit(MealOperationFailure(failure.message)),
      (meals) async {
        for (var meal in meals) {
          await repository.deleteMealLog(meal.id, event.date);
        }
        add(LoadMealsForDate(event.date));
      },
    );
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<MealState> emit,
  ) async {
    // Default range: Last 12 months from today to cover all views
    final now = DateTime.now();
    final start =
        event.start ??
        DateTime(now.year - 1, now.month, now.day); // 1 year back
    final end =
        event.end ??
        DateTime(
          now.year + 1,
          12,
          31,
        ); // End of next year to be safe, or just ample future.

    // We don't emit Loading to avoid full screen spinner if possible,
    // or we can emit a specific loading state if the UI handles it separately.
    // For now, let's just fetch side-effect or emit if we want.
    // Actually, UI needs data.
    // Let's not emit MealLoading() because it might clear the whole screen.
    // But since we navigate to a new page, it's fine.
    // However, if we refresh tabs...
    // Let's just fetch and emit Loaded.

    emit(MealLoading()); // Emit loading for shimmer
    final result = await repository.getDailySummaries(start, end);
    result.fold(
      (failure) => emit(MealOperationFailure(failure.message)),
      (summaries) => emit(DashboardStatsLoaded(summaries)),
    );
  }

  Future<void> _onLoadMeals(
    LoadMealsForDate event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    final result = await repository.getMealsForDate(event.date);
    result.fold(
      (failure) => emit(MealOperationFailure(failure.message)),
      (meals) => emit(MealsLoaded(meals, event.date)),
    );
  }

  Future<void> _onLogMeal(LogMealEvent event, Emitter<MealState> emit) async {
    emit(MealSaving());
    final result = await repository.logMeal(event.log);
    result.fold((failure) => emit(MealOperationFailure(failure.message)), (
      success,
    ) {
      emit(MealConsumptionLogged());
      // Optionally reload the day's meals
      add(LoadMealsForDate(event.log.timestamp));
    });
  }

  Future<void> _onSearchFood(
    SearchFoodEvent event,
    Emitter<MealState> emit,
  ) async {
    // If we want to keep current meals while searching, we might need a complex state.
    // For now, let's assume Search is a distinct mode/page using this Bloc.
    if (event.query.isEmpty) {
      emit(const FoodSearchResults([]));
      return;
    }

    emit(FoodSearchLoading());
    final result = await repository.searchFood(event.query);
    result.fold(
      (failure) => emit(MealOperationFailure(failure.message)),
      (items) => emit(FoodSearchResults(items)),
    );
  }

  Future<void> _onLoadUserLibrary(
    LoadUserLibrary event,
    Emitter<MealState> emit,
  ) async {
    emit(MealLoading());
    // Fetch both foods and meals
    // In a real app, optimize this to run in parallel or stream.
    final foodsResult = await repository.getUserFoods();
    final mealsResult = await repository.getUserMeals();

    foodsResult.fold((failure) => emit(MealOperationFailure(failure.message)), (
      foods,
    ) {
      mealsResult.fold((failure) => emit(MealOperationFailure(failure.message)), (
        meals,
      ) {
        // Sort descending by creation date (newest first)
        // Since lists from repo might be immutable or shared, creating modifiable copies is safer.
        final sortedFoods = List<FoodItem>.from(foods);
        sortedFoods.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );

        final sortedMeals = List<UserMeal>.from(meals);
        sortedMeals.sort(
          (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
            a.createdAt ?? DateTime(0),
          ),
        );

        emit(UserLibraryLoaded(sortedFoods, sortedMeals));
      });
    });
  }

  Future<void> _onAddUserFood(
    AddUserFood event,
    Emitter<MealState> emit,
  ) async {
    emit(MealSaving());
    final result = await repository.saveUserFood(event.food);
    result.fold((failure) => emit(MealOperationFailure(failure.message)), (
      success,
    ) {
      emit(UserLibraryItemSaved());
      add(LoadUserLibrary()); // Reload library
    });
  }

  Future<void> _onAddUserMeal(
    AddUserMeal event,
    Emitter<MealState> emit,
  ) async {
    emit(MealSaving());
    final result = await repository.saveUserMeal(event.meal);
    result.fold((failure) => emit(MealOperationFailure(failure.message)), (
      success,
    ) {
      emit(UserLibraryItemSaved());
      add(LoadUserLibrary()); // Reload library
    });
  }

  Future<void> _onReplaceMealLog(
    ReplaceMealLogEvent event,
    Emitter<MealState> emit,
  ) async {
    emit(MealSaving());
    // 1. Delete all old logs
    for (final id in event.oldLogIds) {
      final deleteResult = await repository.deleteMealLog(id, event.oldDate);
      // If delete fails, we assume it might not exist or network err.
      // We proceed or fail? Let's proceed to try to save the new one,
      // but ideally we should be robust.
      // If delete fails, we might end up with duplicates.
      if (deleteResult.isLeft()) {
        // Log intent? Or just emit failure?
        // Let's stop and emit failure to prevent partial state.
        emit(
          MealOperationFailure(
            'Failed to update meal: Could not remove old entry.',
          ),
        );
        return;
      }
    }

    // 2. Add new log
    final result = await repository.logMeal(event.newLog);
    result.fold((failure) => emit(MealOperationFailure(failure.message)), (
      success,
    ) {
      emit(MealConsumptionLogged());
      add(LoadMealsForDate(event.newLog.timestamp));
    });
  }

  Future<void> _onDeleteMealLog(
    DeleteMealLog event,
    Emitter<MealState> emit,
  ) async {
    // Optimistic update could be done here, but safe bet is to reload
    final result = await repository.deleteMealLog(event.mealLogId, event.date);
    result.fold((failure) => emit(MealOperationFailure(failure.message)), (
      success,
    ) {
      // Reload meals for the date
      add(LoadMealsForDate(event.date));
    });
  }
}
