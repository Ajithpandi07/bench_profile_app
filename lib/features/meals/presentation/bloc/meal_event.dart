import 'package:equatable/equatable.dart';
import '../../domain/entities/entities.dart';

abstract class MealEvent extends Equatable {
  const MealEvent();

  @override
  List<Object> get props => [];
}

class LoadMealsForDate extends MealEvent {
  final DateTime date;
  const LoadMealsForDate(this.date);

  @override
  List<Object> get props => [date];
}

class LogMealEvent extends MealEvent {
  final MealLog log;
  const LogMealEvent(this.log);

  @override
  List<Object> get props => [log];
}

class SearchFoodEvent extends MealEvent {
  final String query;
  const SearchFoodEvent(this.query);

  @override
  List<Object> get props => [query];
}

class LoadUserLibrary extends MealEvent {}

class AddUserFood extends MealEvent {
  final FoodItem food;
  const AddUserFood(this.food);
  @override
  List<Object> get props => [food];
}

class AddUserMeal extends MealEvent {
  final UserMeal meal;
  const AddUserMeal(this.meal);
  @override
  List<Object> get props => [meal];
}

class LoadDashboardStats extends MealEvent {
  final DateTime? start; // Optional: Override default range
  final DateTime? end;

  const LoadDashboardStats({this.start, this.end});

  @override
  List<Object> get props => [start ?? DateTime(0), end ?? DateTime(0)];
}
