import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../models/sleep_log_model.dart';
import '../../domain/entities/sleep_log.dart';
import '../models/sleep_monthly_summary_model.dart';

abstract class SleepRemoteDataSource {
  Future<void> logSleep(SleepLog log);
  Future<List<SleepLog>> getSleepLogs(DateTime date);
  Future<List<SleepLog>> getSleepLogsInRange(DateTime start, DateTime end);
  Future<void> deleteSleepLog(SleepLog log);
}

class SleepRemoteDataSourceImpl implements SleepRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  SleepRemoteDataSourceImpl({required this.firestore, required this.auth});

  @override
  Future<void> logSleep(SleepLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final String docId = log.id.isEmpty
        ? firestore.collection('temp').doc().id
        : log.id;

    final model = SleepLogModel(
      id: docId,
      startTime: log.startTime,
      endTime: log.endTime,
      quality: log.quality,
      notes: log.notes,
    );

    final logRef = firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(docId);

    await logRef.set(model.toMap());

    // Update Monthly Summary
    await _updateMonthlySummary(user.uid, log);
  }

  @override
  Future<List<SleepLog>> getSleepLogs(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    // Range for the entire day (based on End Date)
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    final snapshot = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .where(
          'end_time',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('end_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('end_time') // Sort by end time
        .get();

    return snapshot.docs
        .map((doc) => SleepLogModel.fromFirestore(doc))
        .cast<SleepLog>()
        .toList();
  }

  @override
  Future<List<SleepLog>> getSleepLogsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    // Optimization: If range > 7 days, try using Monthly Summaries
    if (end.difference(start).inDays > 7) {
      try {
        final summaryLogs = await _getLogsFromMonthlySummaries(
          user.uid,
          start,
          end,
        );
        if (summaryLogs.isNotEmpty) {
          return summaryLogs;
        }
      } catch (e) {
        // Fallback to legacy daily iteration if summary fails or doesn't exist
      }
    }

    // Fallback or Short Range: Direct Query
    final snapshot = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .where('end_time', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('end_time', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('end_time')
        .get();

    return snapshot.docs
        .map((doc) => SleepLogModel.fromFirestore(doc))
        .cast<SleepLog>()
        .toList();
  }

  Future<void> _updateMonthlySummary(String uid, SleepLog log) async {
    final year = log.endTime.year;
    final month = log.endTime.month;
    final summaryId = '$year-${month.toString().padLeft(2, '0')}';
    final summaryRef = firestore
        .collection('bench_profile')
        .doc(uid)
        .collection('sleep_logs_monthly')
        .doc(summaryId);

    return firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(summaryRef);
      SleepMonthlySummaryModel? currentSummary;

      if (snapshot.exists) {
        currentSummary = SleepMonthlySummaryModel.fromFirestore(snapshot);
      }

      final dayKey = log.endTime.day.toString();
      final logDuration = log.duration.inMinutes;

      // Calculate new values
      Map<String, int> dailyBreakdown = currentSummary != null
          ? Map.from(currentSummary.dailyBreakdown)
          : {};

      // Update specific day. Note: This simple logic assumes one log per day dominates or sums?
      // For simplicity in this optimization, we add to the day if multiple logs exist,
      // or replace if we want strict nightly log style.
      // Given SleepLog structure, let's SUM for the day.
      int currentDayVal = dailyBreakdown[dayKey] ?? 0;
      dailyBreakdown[dayKey] = currentDayVal + logDuration;

      // Recalculate totals
      int totalMinutes = 0;
      int daysWithData = 0;
      double newAvgQuality =
          currentSummary?.avgQuality ?? log.quality.toDouble();

      final newSummary = SleepMonthlySummaryModel(
        id: summaryId,
        year: year,
        month: month,
        totalDurationMinutes: totalMinutes,
        daysWithData: daysWithData,
        avgQuality: newAvgQuality,
        dailyBreakdown: dailyBreakdown,
      );

      transaction.set(summaryRef, newSummary.toMap());
    });
  }

  Future<List<SleepLog>> _getLogsFromMonthlySummaries(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    // Determine months needed
    // E.g. Start 2025-01-01 End 2025-12-31 -> 12 docs
    List<SleepLog> syntheticLogs = [];

    DateTime currentMonth = DateTime(start.year, start.month);
    while (currentMonth.isBefore(end) ||
        currentMonth.month == end.month && currentMonth.year == end.year) {
      final summaryId =
          '${currentMonth.year}-${currentMonth.month.toString().padLeft(2, '0')}';
      final doc = await firestore
          .collection('bench_profile')
          .doc(uid)
          .collection('sleep_logs_monthly')
          .doc(summaryId)
          .get();

      if (doc.exists) {
        final summary = SleepMonthlySummaryModel.fromFirestore(doc);
        summary.dailyBreakdown.forEach((dayStr, minutes) {
          final day = int.parse(dayStr);
          final logDate = DateTime(summary.year, summary.month, day);

          if (logDate.isAfter(start.subtract(const Duration(days: 1))) &&
              logDate.isBefore(end.add(const Duration(days: 1)))) {
            syntheticLogs.add(
              SleepLog(
                id: 'synthetic_$day',
                startTime: logDate.subtract(
                  Duration(minutes: minutes),
                ), // Approximate start
                endTime: logDate, // Date key represents wake-up day (End Date)
                quality: summary.avgQuality.toInt(),
              ),
            );
          }
        });
      }

      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
    }

    return syntheticLogs;
  }

  @override
  Future<void> deleteSleepLog(SleepLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(log.id)
        .delete();
  }
}
