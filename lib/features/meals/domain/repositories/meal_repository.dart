import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import '../entities/entities.dart';

abstract class MealRepository {
  Future<Either<Failure, void>> logMeal(MealLog log);
  Future<Either<Failure, List<MealLog>>> getMealsForDate(DateTime date);
  Future<Either<Failure, List<FoodItem>>> searchFood(String query);
  Future<Either<Failure, void>> saveCustomFood(FoodItem food);
  Future<Either<Failure, void>> saveUserFood(FoodItem food);
  Future<Either<Failure, List<FoodItem>>> getUserFoods();
  Future<Either<Failure, void>> saveUserMeal(UserMeal meal);
  Future<Either<Failure, List<UserMeal>>> getUserMeals();
}
