import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../core/error/exceptions.dart';
import '../../domain/entities/activity_log.dart';

import '../../domain/entities/daily_activity_summary.dart';

abstract class ActivityRemoteDataSource {
  Future<void> logActivity(ActivityLog activity);
  Future<List<ActivityLog>> getActivitiesForDate(DateTime date);
  Future<void> deleteActivity(String id, DateTime date);
  Future<void> updateActivity(ActivityLog activity);
  Future<List<DailyActivitySummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  );
}

class ActivityRemoteDataSourceImpl implements ActivityRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  // Collection variables
  static const String _collectionName = 'fitnessprofile';
  static const String _logSubCollection = 'activity_logs';
  static const String _monthlySubCollection = 'activity_logs_monthly';

  ActivityRemoteDataSourceImpl({required this.firestore, required this.auth});

  // Helper methods
  CollectionReference<Map<String, dynamic>> _getActivityLogsCollection(
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

  @override
  Future<void> logActivity(ActivityLog activity) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${activity.startTime.year}-${activity.startTime.month.toString().padLeft(2, '0')}-${activity.startTime.day.toString().padLeft(2, '0')}';

    final batch = firestore.batch();

    // 1. Save detailed log
    // 1. Save detailed log
    final logRef = _getActivityLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs').doc(activity.id);

    batch.set(logRef, {
      'id': activity.id,
      'userId': user.uid,
      'activityType': activity.activityType,
      'customActivityName': activity.customActivityName,
      'startTime': Timestamp.fromDate(activity.startTime),
      'durationMinutes': activity.durationMinutes,
      'caloriesBurned': activity.caloriesBurned,
      'createdAt': activity.createdAt != null
          ? Timestamp.fromDate(activity.createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'notes': activity.notes,
    });

    // 2. DAILY Total (Atomic Increment)
    // 2. DAILY Total (Atomic Increment)
    final dateDocRef = _getActivityLogsCollection(user.uid).doc(dateId);

    batch.set(dateDocRef, {
      'totalCalories': FieldValue.increment(activity.caloriesBurned),
      'totalDuration': FieldValue.increment(activity.durationMinutes),
      'date': Timestamp.fromDate(
        DateTime(
          activity.startTime.year,
          activity.startTime.month,
          activity.startTime.day,
        ),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. MONTHLY Total (Atomic Increment)
    final year = activity.startTime.year;
    final month = activity.startTime.month;
    final day = activity.startTime.day;
    final summaryId = '${year}_$month';

    final summaryRef = _getMonthlyCollection(user.uid).doc(summaryId);

    // Use set(merge:true) to ensure doc exists, then update() for nested increments.
    batch.set(summaryRef, {
      'id': summaryId,
      'userId': user.uid,
      'year': year,
      'month': month,
    }, SetOptions(merge: true));

    batch.update(summaryRef, {
      'totalCalories': FieldValue.increment(activity.caloriesBurned),
      'totalDuration': FieldValue.increment(activity.durationMinutes),
      'dailyBreakdown.${day.toString()}': FieldValue.increment(
        activity.caloriesBurned,
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<List<ActivityLog>> getActivitiesForDate(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final query = await _getActivityLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs').orderBy('startTime').get();

    return query.docs.map((doc) {
      final data = doc.data();
      return ActivityLog(
        id: data['id'],
        userId: data['userId'],
        activityType: data['activityType'],
        customActivityName: data['customActivityName'],
        startTime: (data['startTime'] as Timestamp).toDate(),
        durationMinutes: (data['durationMinutes'] as num).toInt(),
        caloriesBurned: (data['caloriesBurned'] as num).toDouble(),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : null,
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : null,
        notes: data['notes'],
      );
    }).toList();
  }

  @override
  Future<void> deleteActivity(String id, DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final logRef = _getActivityLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs').doc(id);

    final logSnapshot = await logRef.get();
    if (!logSnapshot.exists) return;

    final logData = logSnapshot.data()!;
    final totalCalories = (logData['caloriesBurned'] as num).toDouble();
    final duration = (logData['durationMinutes'] as num).toInt();

    final batch = firestore.batch();

    // 1. Delete Log
    batch.delete(logRef);

    // 2. Decrement Daily Total
    // 2. Decrement Daily Total
    final dateDocRef = _getActivityLogsCollection(user.uid).doc(dateId);

    batch.set(dateDocRef, {
      'totalCalories': FieldValue.increment(-totalCalories),
      'totalDuration': FieldValue.increment(-duration),
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
      'totalCalories': FieldValue.increment(-totalCalories),
      'totalDuration': FieldValue.increment(-duration),
      'dailyBreakdown.${day.toString()}': FieldValue.increment(-totalCalories),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  @override
  Future<void> updateActivity(ActivityLog activity) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    final dateId =
        '${activity.startTime.year}-${activity.startTime.month.toString().padLeft(2, '0')}-${activity.startTime.day.toString().padLeft(2, '0')}';

    final logRef = _getActivityLogsCollection(
      user.uid,
    ).doc(dateId).collection('logs').doc(activity.id);

    await firestore.runTransaction((transaction) async {
      final doc = await transaction.get(logRef);
      if (!doc.exists) {
        throw ServerException("Activity log not found");
      }

      final data = doc.data()!;
      final oldCalories = (data['caloriesBurned'] as num).toDouble();
      final oldDuration = (data['durationMinutes'] as num).toInt();

      final calDiff = activity.caloriesBurned - oldCalories;
      final durDiff = activity.durationMinutes - oldDuration;

      // Update Log
      transaction.update(logRef, {
        'activityType': activity.activityType,
        'customActivityName': activity.customActivityName,
        'startTime': Timestamp.fromDate(activity.startTime),
        'durationMinutes': activity.durationMinutes,
        'caloriesBurned': activity.caloriesBurned,
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': activity.notes,
      });

      // Update Daily
      final dateDocRef = _getActivityLogsCollection(user.uid).doc(dateId);

      transaction.set(dateDocRef, {
        'totalCalories': FieldValue.increment(calDiff),
        'totalDuration': FieldValue.increment(durDiff),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Monthly
      final year = activity.startTime.year;
      final month = activity.startTime.month;
      final day = activity.startTime.day;
      final summaryId = '${year}_$month';

      final summaryRef = _getMonthlyCollection(user.uid).doc(summaryId);

      transaction.set(summaryRef, {
        'id': summaryId,
        'userId': user.uid,
        'year': year,
        'month': month,
      }, SetOptions(merge: true));

      transaction.update(summaryRef, {
        'totalCalories': FieldValue.increment(calDiff),
        'totalDuration': FieldValue.increment(durDiff),
        'dailyBreakdown.${day.toString()}': FieldValue.increment(calDiff),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  @override
  Future<List<DailyActivitySummary>> getDailySummaries(
    DateTime start,
    DateTime end,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User not authenticated');

    List<DailyActivitySummary> summaries = [];
    final startMonth = DateTime(start.year, start.month);
    final endMonth = DateTime(end.year, end.month);

    // Iterate through months in the range
    DateTime currentMonth = startMonth;
    while (currentMonth.isBefore(endMonth) ||
        currentMonth.isAtSameMomentAs(endMonth)) {
      final summaryId = '${currentMonth.year}_${currentMonth.month}';
      final docRef = _getMonthlyCollection(user.uid).doc(summaryId);

      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final dailyBreakdown = data['dailyBreakdown'] as Map<String, dynamic>?;

        if (dailyBreakdown != null) {
          dailyBreakdown.forEach((dayStr, calories) {
            final day = int.tryParse(dayStr);
            // Duration breakdown is not currently stored in dailyBreakdown, only totalCalories.
            // If we need duration stats per day, we need to update logActivity to store it in dailyBreakdown too.
            // For now, let's assume calories is the main stat or 0 duration.
            // Or better, we should fetch from 'activity_logs' collection daily doc if we want granular.
            // But wait, the daily aggregate 'activity_logs/{dateId}' has 'totalCalories' and 'totalDuration'.
            // Fetching that might be better than the monthly map if we traverse days.
            // BUT, iterating days is expensive if range is large (Yearly view).
            // Monthly doc is better for range.
            // Let's stick to dailyBreakdown map. If it only has calories, that's what we get.
            // Current logActivity: 'dailyBreakdown': { day.toString(): FieldValue.increment(activity.caloriesBurned) }
            // Only calories. Users requested stats dashboard which prioritizes calories usually.

            if (day != null) {
              final date = DateTime(currentMonth.year, currentMonth.month, day);
              if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
                  (date.isBefore(end) || date.isAtSameMomentAs(end))) {
                final cal = (calories as num).toDouble();
                summaries.add(
                  DailyActivitySummary(
                    date: date,
                    totalCalories: cal,
                    totalDuration:
                        0, // Placeholder as currently not stored in map
                  ),
                );
              }
            }
          });
        }
      }

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }
    return summaries;
  }
}
