import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/error/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/daily_meal_summary.dart';

abstract class MealRemoteDataSource {
  Future<void> logMeal(MealLog log);
  Future<List<MealLog>> getMealsForDate(DateTime date);
  Future<void> saveUserFood(FoodItem food);
  Future<List<FoodItem>> getUserFoods();
  Future<void> saveUserMeal(UserMeal meal);
  Future<List<UserMeal>> getUserMeals();
  Future<List<UserMeal>> getUserMeals();
  Future<List<DailyMealSummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  );
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

    // 1b. Update daily total calories
    final dateDocRef = firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('meal_logs')
        .doc(dateId);

    await dateDocRef.set({
      'totalCalories': FieldValue.increment(log.totalCalories),
      'date': Timestamp.fromDate(
        DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Normalize: Store only necessary fields
    await logRef.set({
      'id': log.id,
      'userId': user.uid,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'mealType': log.mealType,
      'totalCalories': log.totalCalories,
      'userMeals': log.userMeals.map((m) => m.toMap(isSnapshot: true)).toList(),
      'createdAt': log.createdAt != null
          ? Timestamp.fromDate(log.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'items': log.items
          .map(
            (item) => {
              'id': item.id,
              'calories': item.calories,
              'quantity': item.quantity,
              'servingSize': item.servingSize,
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

    // 1. Fetch the lean meal logs
    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('meal_logs')
        .doc(dateId)
        .collection('logs')
        .orderBy('timestamp')
        .get();

    if (query.docs.isEmpty) return [];

    // 2. Fetch User Foods to re-hydrate the full details
    // Optimization: In a real app, query only needed IDs using whereIn (chunks of 10)
    // For now, fetching all user foods is acceptable or we rely on what we have.
    // Let's assume we need to fetch all to be safe or map them.
    final userFoods = await getUserFoods();
    final foodMap = {for (var f in userFoods) f.id: f};

    return query.docs.map((doc) {
      final data = doc.data();
      final itemsList = (data['items'] as List);

      // Re-hydrate items
      final hydratedItems = itemsList.map((i) {
        final id = i['id'] ?? '';
        final snapshotCalories = (i['calories'] as num).toDouble();
        final quantity = i['quantity'] ?? 1;
        final serving = i['servingSize'] ?? '';

        final definition = foodMap[id];
        if (definition != null) {
          // Merge definition with specific snapshot data (like quantity/calories)
          // Note: Calories in definition are per unit. Snapshot calories might be total or per unit?
          // Usually logs store total calories for that entry.
          // FoodItem.calories generic is 'per serving/quantity 1' usually?
          // Let's rely on the definitions macros but respect the logged quantities.
          return definition.copyWith(
            quantity: quantity,
            calories: snapshotCalories, // keep the logged calorie value?
            servingSize: serving,
          );
        } else {
          // Fallback if food definition missing (deleted or legacy)
          return FoodItem(
            id: id,
            name: 'Unknown Food', // or store name in log as fallback
            calories: snapshotCalories,
            quantity: quantity,
            servingSize: serving,
          );
        }
      }).toList();

      return MealLog(
        id: data['id'],
        userId: data['userId'],
        timestamp: (data['timestamp'] as Timestamp).toDate(),
        mealType: data['mealType'],
        totalCalories: (data['totalCalories'] as num).toDouble(),
        items: hydratedItems,
        userMeals:
            (data['userMeals'] as List<dynamic>?)
                ?.map((e) => UserMeal.fromMap(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
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
          'createdAt': food.createdAt != null
              ? Timestamp.fromDate(food.createdAt!)
              : FieldValue.serverTimestamp(),
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
        createdAt: i['createdAt'] != null
            ? (i['createdAt'] as Timestamp).toDate()
            : null,
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

    // 1. Fetch User Meals
    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('user_meals')
        .get();

    if (query.docs.isEmpty) return [];

    // 2. Fetch User Foods for hydration (legacy support)
    // We only strictly need this if we encounter docs with 'foodIds' but no 'foods'.
    // To be safe and ensure robustness, we fetch them.
    final userFoods = await getUserFoods();
    final foodMap = {for (var f in userFoods) f.id: f};

    return query.docs.map<UserMeal>((doc) {
      final data = doc.data();

      // Check if we have the modern 'foods' list structure
      if (data['foods'] != null && (data['foods'] as List).isNotEmpty) {
        return UserMeal.fromMap(data);
      }

      // Legacy Fallback: Hydrate from 'foodIds' if available
      List<FoodItem> hydratedFoods = [];
      if (data['foodIds'] != null) {
        final ids = List<String>.from(data['foodIds'] as List);
        hydratedFoods = ids
            .map((id) => foodMap[id])
            .whereType<FoodItem>()
            .toList(); // Filter out nulls
      }
    }).toList();
  }

  @override
  Future<List<DailyMealSummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final query = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('meal_logs')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return DailyMealSummary(
        date: (data['date'] as Timestamp).toDate(),
        totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
