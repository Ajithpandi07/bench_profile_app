import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import '../../domain/entities/entities.dart';

abstract class MealRemoteDataSource {
  Future<void> logMeal(MealLog log);
  Future<List<MealLog>> getMealsForDate(DateTime date);
  Future<void> saveUserFood(FoodItem food);
  Future<List<FoodItem>> getUserFoods();
  Future<void> saveUserMeal(UserMeal meal);
  Future<List<UserMeal>> getUserMeals();
  // Future<List<FoodItem>> searchFood(String query); // Optional: if using external API or local DB
}

class MealRemoteDataSourceImpl implements MealRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MealRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<void> logMeal(MealLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';

    // 1. Save detailed log in 'meal_logs' collection
    final logRef = firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('meal_logs')
        .doc(dateId)
        .collection('logs')
        .doc(log.id);

    await logRef.set({
      'id': log.id,
      'userId': user.uid,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'mealType': log.mealType,
      'totalCalories': log.totalCalories,
      'items': log.items
          .map(
            (item) => {
              'id': item.id,
              'name': item.name,
              'calories': item.calories,
              'carbs': item.carbs,
              'protein': item.protein,
              'fat': item.fat,
              'servingSize': item.servingSize,
              'quantity': item.quantity,
              'sodium': item.sodium,
              'potassium': item.potassium,
              'dietaryFibre': item.dietaryFibre,
              'sugars': item.sugars,
              'vitaminA': item.vitaminA,
              'vitaminC': item.vitaminC,
              'calcium': item.calcium,
              'iron': item.iron,
            },
          )
          .toList(),
    });
  }

  @override
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('meal_logs')
        .doc(dateId)
        .collection('logs')
        .orderBy('timestamp')
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return MealLog(
        id: data['id'],
        userId: data['userId'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        mealType: data['mealType'],
        totalCalories: (data['totalCalories'] as num).toDouble(),
        items: (data['items'] as List)
            .map(
              (i) => FoodItem(
                id: i['id'] ?? '',
                name: i['name'] ?? 'Unknown',
                calories: (i['calories'] as num).toDouble(),
                carbs: (i['carbs'] as num?)?.toDouble() ?? 0,
                protein: (i['protein'] as num?)?.toDouble() ?? 0,
                fat: (i['fat'] as num?)?.toDouble() ?? 0,
                servingSize: i['servingSize'] ?? '',
                quantity: i['quantity'] ?? 1,
                sodium: (i['sodium'] as num?)?.toDouble() ?? 0,
                potassium: (i['potassium'] as num?)?.toDouble() ?? 0,
                dietaryFibre: (i['dietaryFibre'] as num?)?.toDouble() ?? 0,
                sugars: (i['sugars'] as num?)?.toDouble() ?? 0,
                vitaminA: (i['vitaminA'] as num?)?.toDouble() ?? 0,
                vitaminC: (i['vitaminC'] as num?)?.toDouble() ?? 0,
                calcium: (i['calcium'] as num?)?.toDouble() ?? 0,
                iron: (i['iron'] as num?)?.toDouble() ?? 0,
              ),
            )
            .toList(),
      );
    }).toList();
  }

  @override
  Future<void> saveUserFood(FoodItem food) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('user_foods')
        .doc(food.id)
        .set({
          'id': food.id,
          'name': food.name,
          'calories': food.calories,
          'carbs': food.carbs,
          'protein': food.protein,
          'fat': food.fat,
          'servingSize': food.servingSize,
          'quantity': food.quantity,
          'sodium': food.sodium,
          'potassium': food.potassium,
          'dietaryFibre': food.dietaryFibre,
          'sugars': food.sugars,
          'vitaminA': food.vitaminA,
          'vitaminC': food.vitaminC,
          'calcium': food.calcium,
          'iron': food.iron,
        });
  }

  @override
  Future<List<FoodItem>> getUserFoods() async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('user_foods')
        .get();

    return query.docs.map((doc) {
      final i = doc.data();
      return FoodItem(
        id: i['id'] ?? '',
        name: i['name'] ?? 'Unknown',
        calories: (i['calories'] as num).toDouble(),
        carbs: (i['carbs'] as num?)?.toDouble() ?? 0,
        protein: (i['protein'] as num?)?.toDouble() ?? 0,
        fat: (i['fat'] as num?)?.toDouble() ?? 0,
        servingSize: i['servingSize'] ?? '',
        quantity: i['quantity'] ?? 1,
        sodium: (i['sodium'] as num?)?.toDouble() ?? 0,
        potassium: (i['potassium'] as num?)?.toDouble() ?? 0,
        dietaryFibre: (i['dietaryFibre'] as num?)?.toDouble() ?? 0,
        sugars: (i['sugars'] as num?)?.toDouble() ?? 0,
        vitaminA: (i['vitaminA'] as num?)?.toDouble() ?? 0,
        vitaminC: (i['vitaminC'] as num?)?.toDouble() ?? 0,
        calcium: (i['calcium'] as num?)?.toDouble() ?? 0,
        iron: (i['iron'] as num?)?.toDouble() ?? 0,
      );
    }).toList();
  }

  @override
  Future<void> saveUserMeal(UserMeal meal) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('user_meals')
        .doc(meal.id)
        .set(meal.toMap());
  }

  @override
  Future<List<UserMeal>> getUserMeals() async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('user_meals')
        .get();

    return query.docs.map((doc) {
      return UserMeal.fromMap(doc.data());
    }).toList();
  }
}
