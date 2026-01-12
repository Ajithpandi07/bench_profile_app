import 'package:dartz/dartz.dart';
import 'package:bench_profile_app/core/error/failures.dart';
import 'package:bench_profile_app/core/network/network_info.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/daily_meal_summary.dart';
import '../../domain/repositories/meal_repository.dart';
import '../datasources/meal_remote_data_source.dart';

class MealRepositoryImpl implements MealRepository {
  final MealRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MealRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> logMeal(MealLog log) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.logMeal(log);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<MealLog>>> getMealsForDate(DateTime date) async {
    if (await networkInfo.isConnected) {
      try {
        final meals = await remoteDataSource.getMealsForDate(date);
        return Right(meals);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // TODO: Implement local cache fallback if needed
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<FoodItem>>> searchFood(String query) async {
    // Mock implementation for demo - Replace with real API or DB later
    // Returning empty list or simple mock results
    final mockFoods = [
      const FoodItem(
        id: '1',
        name: 'Rice',
        calories: 130,
        carbs: 28,
        servingSize: '1 cup',
      ),
      const FoodItem(
        id: '2',
        name: 'Chicken Breast',
        calories: 165,
        protein: 31,
        servingSize: '100g',
      ),
      const FoodItem(
        id: '3',
        name: 'Egg',
        calories: 78,
        protein: 6,
        servingSize: '1 large',
      ),
    ];

    if (query.isEmpty) return const Right([]);

    final results = mockFoods
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Right(results);
  }

  @override
  Future<Either<Failure, void>> saveCustomFood(FoodItem food) async {
    // Legacy: Redirecting to saveUserFood
    return saveUserFood(food);
  }

  @override
  Future<Either<Failure, void>> saveUserFood(FoodItem food) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveUserFood(food);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<FoodItem>>> getUserFoods() async {
    if (await networkInfo.isConnected) {
      try {
        final foods = await remoteDataSource.getUserFoods();
        return Right(foods);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // TODO: Implement local cache fallback
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> saveUserMeal(UserMeal meal) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.saveUserMeal(meal);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<UserMeal>>> getUserMeals() async {
    if (await networkInfo.isConnected) {
      try {
        final meals = await remoteDataSource.getUserMeals();
        return Right(meals);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, List<DailyMealSummary>>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    if (await networkInfo.isConnected) {
      try {
        final summaries = await remoteDataSource.getDailySummaries(start, end);
        return Right(summaries);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMealLog(String id, DateTime date) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deleteMealLog(id, date);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
