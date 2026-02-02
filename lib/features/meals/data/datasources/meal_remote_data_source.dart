import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/error/exceptions.dart';
import '../../domain/entities/entities.dart';
import '../../domain/entities/daily_meal_summary.dart';

abstract class MealRemoteDataSource {
  Future<void> logMeal(MealLog log);
  Future<List<MealLog>> getMealsForDate(DateTime date);
  Future<void> saveUserFood(FoodItem food);
  Future<List<FoodItem>> getUserFoods();
  Future<void> saveUserMeal(UserMeal meal);
  Future<List<UserMeal>> getUserMeals();

  Future<List<DailyMealSummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  );
  Future<void> deleteMealLog(String id, DateTime date);
  Future<void> deleteMultipleMealLogs(List<String> ids, DateTime date);
  Future<void> deleteUserFood(String id);
  Future<void> deleteUserMeal(String id);
}

class MealRemoteDataSourceImpl implements MealRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  // Collection variables
  static const String _collectionName = 'fitnessprofile';
  static const String _logSubCollection = 'meal_logs';
  static const String _monthlySubCollection = 'meal_logs_monthly';
  static const String _userFoodsCollection = 'user_foods';
  static const String _userMealsCollection = 'user_meals';

  MealRemoteDataSourceImpl({required this.firestore, required this.auth});

  // Helper methods
  CollectionReference<Map<String, dynamic>> _getMealLogsCollection(
    String userId,
  ) {
    return firestore
        .collection(_collectionName)
        .doc(userId)
        .collection(_logSubCollection);
  }

  CollectionReference<Map<String, dynamic>> _getMonthlyCollection(
    String userId,
  ) {
    return firestore
        .collection(_collectionName)
        .doc(userId)
        .collection(_monthlySubCollection);
  }

  CollectionReference<Map<String, dynamic>> _getUserFoodsCollection(
    String userId,
  ) {
    return firestore
        .collection(_collectionName)
        .doc(userId)
        .collection(_userFoodsCollection);
  }

  CollectionReference<Map<String, dynamic>> _getUserMealsCollection(
    String userId,
  ) {
    return firestore
        .collection(_collectionName)
        .doc(userId)
        .collection(_userMealsCollection);
  }

  @override
  Future<void> logMeal(MealLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${log.timestamp.year}-${log.timestamp.month.toString().padLeft(2, '0')}-${log.timestamp.day.toString().padLeft(2, '0')}';

    final batch = firestore.batch();
    final logsCollection = _getMealLogsCollection(user.uid);

    // 1. Save detailed log
    final logRef = logsCollection.doc(dateId).collection('logs').doc(log.id);

    batch.set(logRef, {
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
              'name': item.name,
              'calories': item.calories,
              'carbs': item.carbs,
              'protein': item.protein,
              'fat': item.fat,
              'quantity': item.quantity,
              'servingSize': item.servingSize,
            },
          )
          .toList(),
    });

    // 2. DAILY Total (Atomic Increment)
    final dateDocRef = logsCollection.doc(dateId);

    batch.set(dateDocRef, {
      'totalCalories': FieldValue.increment(log.totalCalories),
      'date': Timestamp.fromDate(
        DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. MONTHLY Total (Atomic Increment)
    final year = log.timestamp.year;
    final month = log.timestamp.month;
    final day = log.timestamp.day;
    final summaryId = '${year}_$month';

    final summaryRef = _getMonthlyCollection(user.uid).doc(summaryId);

    // Note: Use set(merge:true) to ensure doc exists, then update() for nested dot notation.
    batch.set(summaryRef, {
      'id': summaryId,
      'userId': user.uid,
      'year': year,
      'month': month,
    }, SetOptions(merge: true));

    batch.update(summaryRef, {
      'totalCalories': FieldValue.increment(log.totalCalories),
      'dailyBreakdown.${day.toString()}': FieldValue.increment(
        log.totalCalories,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<List<MealLog>> getMealsForDate(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // 1. Fetch the lean meal logs
    final query = await _getMealLogsCollection(user.uid)
        .doc(dateId)
        .collection('logs')
        .orderBy('timestamp')
        .get(const GetOptions(source: Source.server));

    if (query.docs.isEmpty) return [];

    // 2. Process logs and check if we need to hydrate (Lazy Fetch)
    final docs = query.docs;
    final List<MealLog> resultLogs = [];
    bool needsHydration = false;

    // First pass: Try to build from snapshot
    for (var doc in docs) {
      final data = doc.data();
      final itemsList = (data['items'] as List);

      for (var i in itemsList) {
        if (i['name'] == null) {
          needsHydration = true;
          break;
        }
      }
      if (needsHydration) break;
    }

    Map<String, FoodItem>? foodMap;
    if (needsHydration) {
      // Fallback: Fetch all user foods only if necessary (Legacy logs)
      final userFoods = await getUserFoods();
      foodMap = {for (var f in userFoods) f.id: f};
    }

    for (var doc in docs) {
      final data = doc.data();
      final itemsList = (data['items'] as List);

      // Re-hydrate items
      final hydratedItems = itemsList.map((i) {
        final id = i['id'] ?? '';
        final snapshotCalories = (i['calories'] as num?)?.toDouble() ?? 0.0;
        final quantity = (i['quantity'] as num?)?.toDouble() ?? 1.0;
        final serving = i['servingSize'] ?? '';
        final snapshotName = i['name'];
        final snapshotCarbs = (i['carbs'] as num?)?.toDouble() ?? 0.0;
        final snapshotProtein = (i['protein'] as num?)?.toDouble() ?? 0.0;
        final snapshotFat = (i['fat'] as num?)?.toDouble() ?? 0.0;

        if (snapshotName != null) {
          // Fast path: Data is in the log
          return FoodItem(
            id: id,
            name: snapshotName,
            calories:
                snapshotCalories, // per total or unit? Logic implies these are saved properties
            carbs: snapshotCarbs,
            protein: snapshotProtein,
            fat: snapshotFat,
            quantity: quantity,
            servingSize: serving,
          );
        } else {
          // Slow path: Need hydration
          final definition = foodMap?[id];
          if (definition != null) {
            return definition.copyWith(
              quantity: quantity,
              calories: snapshotCalories,
              servingSize: serving,
            );
          } else {
            return FoodItem(
              id: id,
              name: 'Unknown Food',
              calories: snapshotCalories,
              quantity: quantity,
              servingSize: serving,
            );
          }
        }
      }).toList();

      resultLogs.add(
        MealLog(
          id: data['id'],
          userId: data['userId'],
          timestamp: (data['timestamp'] as Timestamp).toDate(),
          mealType: data['mealType'],
          totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
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
        ),
      );
    }

    return resultLogs;
  }

  @override
  Future<void> saveUserFood(FoodItem food) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    await _getUserFoodsCollection(user.uid).doc(food.id).set({
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

    final query = await _getUserFoodsCollection(user.uid).get();

    return query.docs.map((doc) {
      final i = doc.data();
      return FoodItem(
        id: i['id'] ?? '',
        name: i['name'] ?? 'Unknown',
        calories: (i['calories'] as num?)?.toDouble() ?? 0.0,
        carbs: (i['carbs'] as num?)?.toDouble() ?? 0,
        protein: (i['protein'] as num?)?.toDouble() ?? 0,
        fat: (i['fat'] as num?)?.toDouble() ?? 0,
        servingSize: i['servingSize'] ?? '',
        quantity: (i['quantity'] as num?)?.toDouble() ?? 1.0,
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

    final mealToSave = meal.copyWith(creatorId: user.uid);

    await _getUserMealsCollection(
      user.uid,
    ).doc(mealToSave.id).set(mealToSave.toMap());
  }

  @override
  Future<List<UserMeal>> getUserMeals() async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    // 1. Fetch User Meals
    final query = await _getUserMealsCollection(user.uid).get();

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

      return UserMeal(
        id: data['id'] ?? '',
        name: data['name'] ?? '',
        foods: hydratedFoods,
        totalCalories: (data['totalCalories'] as num?)?.toDouble() ?? 0.0,
        creatorId: data['creatorId'] ?? '',
        quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
      );
    }).toList();
  }

  @override
  Future<List<DailyMealSummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    // Optimization: Use monthly summaries for range > 32 days
    final diff = end.difference(start).inDays;
    if (diff > 32) {
      return _getSummariesFromMonthly(user.uid, start, end);
    }

    final query = await _getMealLogsCollection(user.uid)
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

  Future<List<DailyMealSummary>> _getSummariesFromMonthly(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final summaries = <DailyMealSummary>[];
    try {
      var current = DateTime(start.year, start.month);
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final summaryId = '${current.year}_${current.month}';
        final doc = await _getMonthlyCollection(userId).doc(summaryId).get();

        if (doc.exists) {
          final data = doc.data()!;
          final breakdown = Map<String, dynamic>.from(
            data['dailyBreakdown'] ?? {},
          );
          breakdown.forEach((dayStr, calDynamic) {
            final day = int.tryParse(dayStr);
            if (day != null) {
              final date = DateTime(current.year, current.month, day);
              if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
                  (date.isBefore(end) || date.isAtSameMomentAs(end))) {
                summaries.add(
                  DailyMealSummary(
                    date: date,
                    totalCalories: (calDynamic as num?)?.toDouble() ?? 0.0,
                  ),
                );
              }
            }
          });
        }
        current = DateTime(current.year, current.month + 1);
      }
      return summaries;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> deleteMealLog(String id, DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final logRef = _getMealLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs').doc(id);

    // Note: We need to know the calories of the log we are deleting to decrement.
    // This is the ONE read we cannot easily skip unless we trust the client OR store negative value.
    // However, for consistency, let's fetch it. This is strictly ONE read.
    // The previous implementation had a read + transaction read (2 reads).
    // Now it's 1 read + batch write (0 reads).

    final logSnapshot = await logRef.get();
    if (!logSnapshot.exists) return; // Nothing to delete

    final logData = logSnapshot.data()!;
    final totalCalories = (logData['totalCalories'] as num?)?.toDouble() ?? 0.0;

    final batch = firestore.batch();

    // 1. Delete Log
    batch.delete(logRef);

    // 2. Decrement Daily Total
    // 2. Decrement Daily Total
    final dateDocRef = _getMealLogsCollection(user.uid).doc(dateId);

    batch.set(dateDocRef, {
      'totalCalories': FieldValue.increment(-totalCalories),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. Update Monthly Summary (Decrement)
    final year = date.year;
    final month = date.month;
    final day = date.day;
    final summaryId = '${year}_$month';

    final summaryRef = _getMonthlyCollection(user.uid).doc(summaryId);

    // Use set(merge:true) to ensure doc exists, then update() with dot notation.
    batch.set(summaryRef, {
      'id': summaryId,
      'userId': user.uid,
      'year': year,
      'month': month,
    }, SetOptions(merge: true));

    batch.update(summaryRef, {
      'totalCalories': FieldValue.increment(-totalCalories),
      'dailyBreakdown.${day.toString()}': FieldValue.increment(-totalCalories),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> deleteMultipleMealLogs(List<String> ids, DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final logsCollection = _getMealLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs');

    double totalCaloriesToRemove = 0;
    final batch = firestore.batch();

    // Note: Since each get() is async, we use Future.wait to fetch all required calories in parallel.
    final snapshots = await Future.wait(
      ids.map((id) => logsCollection.doc(id).get()),
    );

    for (var i = 0; i < snapshots.length; i++) {
      final snapshot = snapshots[i];
      if (snapshot.exists) {
        final logData = snapshot.data()!;
        final calories = (logData['totalCalories'] as num?)?.toDouble() ?? 0.0;
        totalCaloriesToRemove += calories;
        batch.delete(logsCollection.doc(ids[i]));
      }
    }

    if (totalCaloriesToRemove > 0) {
      // 2. Decrement Daily Total
      final dateDocRef = _getMealLogsCollection(user.uid).doc(dateId);

      batch.set(dateDocRef, {
        'totalCalories': FieldValue.increment(-totalCaloriesToRemove),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 3. Update Monthly Summary (Decrement)
      final year = date.year;
      final month = date.month;
      final day = date.day;
      final summaryId = '${year}_$month';

      final summaryRef = _getMonthlyCollection(user.uid).doc(summaryId);

      batch.set(summaryRef, {
        'id': summaryId,
        'userId': user.uid,
        'year': year,
        'month': month,
      }, SetOptions(merge: true));

      batch.update(summaryRef, {
        'totalCalories': FieldValue.increment(-totalCaloriesToRemove),
        'dailyBreakdown.${day.toString()}': FieldValue.increment(
          -totalCaloriesToRemove,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> deleteUserFood(String id) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    await _getUserFoodsCollection(user.uid).doc(id).delete();
  }

  @override
  Future<void> deleteUserMeal(String id) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    await _getUserMealsCollection(user.uid).doc(id).delete();
  }
}
