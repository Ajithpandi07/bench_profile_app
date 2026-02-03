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
  final bool wasTargetReached;
  const LogMealEvent(this.log, {this.wasTargetReached = false});

  @override
  List<Object> get props => [log, wasTargetReached];
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
  final bool isEdit;
  const AddUserFood(this.food, {this.isEdit = false});
  @override
  List<Object> get props => [food, isEdit];
}

class AddUserMeal extends MealEvent {
  final UserMeal meal;
  final bool isEdit;
  const AddUserMeal(this.meal, {this.isEdit = false});
  @override
  List<Object> get props => [meal, isEdit];
}

class LoadDashboardStats extends MealEvent {
  final DateTime? start; // Optional: Override default range
  final DateTime? end;

  const LoadDashboardStats({this.start, this.end});

  @override
  List<Object> get props => [start ?? DateTime(0), end ?? DateTime(0)];
}

class ReplaceMealLogEvent extends MealEvent {
  final MealLog newLog;
  final List<String> oldLogIds;
  final DateTime oldDate;

  const ReplaceMealLogEvent({
    required this.newLog,
    required this.oldLogIds,
    required this.oldDate,
  });

  @override
  List<Object> get props => [newLog, oldLogIds, oldDate];
}

class DeleteMealLog extends MealEvent {
  final String mealLogId;
  final DateTime date;

  const DeleteMealLog(this.mealLogId, this.date);

  @override
  List<Object> get props => [mealLogId, date];
}

class DeleteAllMealsForDate extends MealEvent {
  final DateTime date;
  const DeleteAllMealsForDate(this.date);

  @override
  List<Object> get props => [date];
}

class DeleteMultipleMeals extends MealEvent {
  final List<String> mealLogIds;
  final DateTime date;

  const DeleteMultipleMeals(this.mealLogIds, this.date);

  @override
  List<Object> get props => [mealLogIds, date];
}

class DeleteUserFood extends MealEvent {
  final String id;
  const DeleteUserFood(this.id);
  @override
  List<Object> get props => [id];
}

class DeleteUserMeal extends MealEvent {
  final String id;
  const DeleteUserMeal(this.id);
  @override
  List<Object> get props => [id];
}
