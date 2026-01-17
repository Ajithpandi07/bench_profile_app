import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bench_profile_app/core/core.dart';
import 'package:bench_profile_app/features/hydration/domain/entities/hydration_log.dart';
import 'package:bench_profile_app/features/hydration/domain/entities/hydration_daily_summary.dart';

abstract class HydrationRemoteDataSource {
  Future<void> logWaterIntake(HydrationLog log);
  Future<void> deleteHydrationLog(String id, DateTime date);
  Future<List<HydrationLog>> getHydrationLogsForDate(DateTime date);
  Future<List<HydrationDailySummary>> getHydrationStats(
    DateTime startDate,
    DateTime endDate,
  );
}

class HydrationRemoteDataSourceImpl implements HydrationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  HydrationRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<void> logWaterIntake(HydrationLog log) async {
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final date = log.timestamp;
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // 1. Save detailed log
      final docRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId)
          .collection('logs')
          .doc(log.id);

      final data = {
        'id': log.id,
        'userId': user.uid,
        'timestamp': Timestamp.fromDate(log.timestamp),
        'amountLiters': log.amountLiters,
        'beverageType': log.beverageType,
        'createdAt': log.createdAt != null
            ? Timestamp.fromDate(log.createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1b. Update daily total liters (Keep for legacy/daily view speed if needed)
      final dateDocRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId);

      await dateDocRef.set({
        'totalLiters': FieldValue.increment(log.amountLiters),
        'date': Timestamp.fromDate(
          DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day),
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await docRef.set(data);

      // 2. Update Monthly Summary
      await _updateMonthlySummary(user.uid, log);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> _updateMonthlySummary(String userId, HydrationLog log) async {
    final year = log.timestamp.year;
    final month = log.timestamp.month;
    final day = log.timestamp.day;
    final summaryId = '${year}_$month';

    final summaryRef = firestore
        .collection('bench_profile')
        .doc(userId)
        .collection('water_logs_monthly')
        .doc(summaryId);

    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(summaryRef);

      if (!snapshot.exists) {
        transaction.set(summaryRef, {
          'id': summaryId,
          'userId': userId,
          'year': year,
          'month': month,
          'totalLiters': log.amountLiters,
          'dailyBreakdown': {day.toString(): log.amountLiters},
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final data = snapshot.data() as Map<String, dynamic>;
        final currentTotal = (data['totalLiters'] as num?)?.toDouble() ?? 0.0;
        final dailyBreakdown = Map<String, dynamic>.from(
          data['dailyBreakdown'] ?? {},
        );
        final currentDayVal =
            (dailyBreakdown[day.toString()] as num?)?.toDouble() ?? 0.0;

        dailyBreakdown[day.toString()] = currentDayVal + log.amountLiters;

        transaction.update(summaryRef, {
          'totalLiters': currentTotal + log.amountLiters,
          'dailyBreakdown': dailyBreakdown,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  @override
  Future<void> deleteHydrationLog(String id, DateTime date) async {
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final dateDocRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId);

      final logRef = dateDocRef.collection('logs').doc(id);

      // Fetch log to get amount for stats decrement
      final snapshot = await logRef.get();
      if (!snapshot.exists) return;

      final data = snapshot.data();
      final amountLiters = (data?['amountLiters'] as num?)?.toDouble() ?? 0.0;

      final batch = firestore.batch();
      batch.delete(logRef);

      // Decrement Daily Total
      batch.set(dateDocRef, {
        'totalLiters': FieldValue.increment(-amountLiters),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Decrement Monthly Summary
      final year = date.year;
      final month = date.month;
      final day = date.day;
      final summaryId = '${year}_$month';

      final summaryRef = firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs_monthly')
          .doc(summaryId);

      batch.set(summaryRef, {
        'totalLiters': FieldValue.increment(-amountLiters),
        'dailyBreakdown': {day.toString(): FieldValue.increment(-amountLiters)},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await batch.commit();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HydrationLog>> getHydrationLogsForDate(DateTime date) async {
    // ... existing implementation ...
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    try {
      final dateId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final querySnapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .doc(dateId)
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HydrationLog(
          id: data['id'] ?? doc.id,
          userId: data['userId'] ?? '',
          amountLiters: (data['amountLiters'] as num?)?.toDouble() ?? 0.0,
          timestamp: data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
          beverageType: data['beverageType'] ?? 'Regular',
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          updatedAt: data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<HydrationDailySummary>> getHydrationStats(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      throw ServerException('User not authenticated');
    }

    // Optimization: Use monthly summaries for long ranges (> 32 days)
    // For simplicity and to match request, let's use summaries if available or fallback.
    // Actually, user wants optimization.
    // Let's implement fetching from monthly summaries logic.

    final diff = endDate.difference(startDate).inDays;
    if (diff > 32) {
      return _getStatsFromMonthlySummaries(user.uid, startDate, endDate);
    }

    try {
      final querySnapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('water_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return HydrationDailySummary(
          date: (data['date'] as Timestamp).toDate(),
          totalLiters: (data['totalLiters'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<HydrationDailySummary>> _getStatsFromMonthlySummaries(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    final summaries = <HydrationDailySummary>[];
    try {
      // Fetch months in range
      // Simplification: just fetch all monthly logs for these years?
      // Or iterate years/months.
      var current = DateTime(start.year, start.month);
      while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
        final summaryId = '${current.year}_${current.month}';
        final doc = await firestore
            .collection('bench_profile')
            .doc(userId)
            .collection('water_logs_monthly')
            .doc(summaryId)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final breakdown = Map<String, dynamic>.from(
            data['dailyBreakdown'] ?? {},
          );
          breakdown.forEach((dayStr, volDynamic) {
            final day = int.tryParse(dayStr);
            if (day != null) {
              final date = DateTime(current.year, current.month, day);
              if ((date.isAfter(start) || date.isAtSameMomentAs(start)) &&
                  (date.isBefore(end) || date.isAtSameMomentAs(end))) {
                summaries.add(
                  HydrationDailySummary(
                    date: date,
                    totalLiters: (volDynamic as num).toDouble(),
                  ),
                );
              }
            }
          });
        }

        // Next month
        current = DateTime(current.year, current.month + 1);
      }
      return summaries;
    } catch (e) {
      // Fallback or rethrow
      return [];
    }
  }
}
