import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/daily_meal_summary.dart';

abstract class MealState extends Equatable {
  const MealState();

  @override
  List<Object> get props => [];
}

class MealInitial extends MealState {}

class MealLoading extends MealState {}

class MealsLoaded extends MealState {
  final List<MealLog> meals;
  final DateTime date;

  const MealsLoaded(this.meals, this.date);

  @override
  List<Object> get props => [meals, date];
}

class MealSaving extends MealState {} // For spinner during save

class MealConsumptionLogged extends MealState {}

class MealDeletedSuccess extends MealState {}

class UserLibraryItemSaved extends MealState {}

class MealOperationFailure extends MealState {
  final String message;
  const MealOperationFailure(this.message);

  @override
  List<Object> get props => [message];
}

// Search States can be separate or integrated.
// For simplicity, let's keep search separate or use a different property in MealState if needed.
// Or rely on a separate Bloc for search?
// Let's create a specialized state for Food Search results? state.searchResults?
// Or maybe just a standalone state since it's likely a different page.
class FoodSearchLoading extends MealState {}

class FoodSearchResults extends MealState {
  final List<FoodItem> results;
  const FoodSearchResults(this.results);
  @override
  List<Object> get props => [results];
}

class UserLibraryLoaded extends MealState {
  final List<FoodItem> foods;
  final List<UserMeal> meals;

  const UserLibraryLoaded(this.foods, this.meals);

  @override
  List<Object> get props => [foods, meals];
}

class DashboardStatsLoaded extends MealState {
  final List<DailyMealSummary> summaries;
  const DashboardStatsLoaded(this.summaries);

  @override
  List<Object> get props => [summaries];
}
