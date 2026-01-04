import 'package:bloc/bloc.dart';
import '../../domain/repositories/meal_repository.dart';
import 'meal_event.dart';
import 'meal_state.dart';

class MealBloc extends Bloc<MealEvent, MealState> {
  final MealRepository repository;

  MealBloc({required this.repository}) : super(MealInitial()) {
    on<LoadMealsForDate>(_onLoadMeals);
    on<LogMealEvent>(_onLogMeal);
    on<SearchFoodEvent>(_onSearchFood);
    on<LoadUserLibrary>(_onLoadUserLibrary);
    on<AddUserFood>(_onAddUserFood);
    on<AddUserMeal>(_onAddUserMeal);
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
      emit(MealSaveSuccess());
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
      mealsResult.fold(
        (failure) => emit(MealOperationFailure(failure.message)),
        (meals) => emit(UserLibraryLoaded(foods, meals)),
      );
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
      emit(MealSaveSuccess());
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
      emit(MealSaveSuccess());
      add(LoadUserLibrary()); // Reload library
    });
  }
}
