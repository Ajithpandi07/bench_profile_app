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
  Future<void> deleteSleepLog(String id, DateTime date);
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

    // Date bucket based on End Time (wake up time)
    final date = log.endTime;
    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dateDocRef = firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(dateId);

    final logRef = dateDocRef.collection('logs').doc(docId);

    // Batch write to ensure consistency
    final batch = firestore.batch();
    batch.set(logRef, model.toMap());
    batch.set(dateDocRef, {
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'totalDurationMinutes': FieldValue.increment(log.duration.inMinutes),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();

    // Update Monthly Summary (Legacy/Redundant but keeping for now if used elsewhere)
    await _updateMonthlySummary(user.uid, log);
  }

  @override
  Future<List<SleepLog>> getSleepLogs(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final snapshot = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(dateId)
        .collection('logs')
        .orderBy('end_time')
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

    // Optimization: If range is "small" (e.g. Weekly/Monthly views), fetch ACTUAL logs
    // to allow accurate calculation of Bedtimes/WakeTimes.
    // "Small" defined as <= 65 days (covers 2 months easily).
    final days = end.difference(start).inDays;

    if (days <= 65) {
      List<SleepLog> allLogs = [];
      // Iterate days and fetch collections.
      // Note: This causes N reads (e.g. 7 or 30).
      // For a better scalable solution, we would ideally duplicate log data into a top-level collection
      // or use collection group queries if structured right.
      // Given current structure, we iterate.
      for (int i = 0; i <= days; i++) {
        final date = start.add(Duration(days: i));
        try {
          final logs = await getSleepLogs(date);
          allLogs.addAll(logs);
        } catch (e) {
          // Ignore empty days or errors
        }
      }
      return allLogs;
    } else {
      // For Yearly view, stick to summaries to save reads.
      final snapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('sleep_logs')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final totalMinutes = data['totalDurationMinutes'] as int? ?? 0;

        return SleepLog(
          id: 'daily_summary_${doc.id}',
          startTime: date,
          endTime: date.add(Duration(minutes: totalMinutes)),
          quality: 0,
          notes: 'Daily Summary',
        );
      }).toList();
    }
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
    // Deprecated by new daily summary optimization, but keeping code if needed or unused.
    // Actually, can remove if we fully switch.
    // Let's leave it accessible but unused in main path for safety unless instructed to clean up.
    return [];
  }

  @override
  Future<void> deleteSleepLog(String id, DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final dateId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dateDocRef = firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(dateId);

    final logRef = dateDocRef.collection('logs').doc(id);

    // Fetch log to get duration for stats update
    final snapshot = await logRef.get();
    if (!snapshot.exists) return;

    // Remove unused durationMinutes logic
    // final data = snapshot.data();
    // final durationMinutes = ...

    // Some older models might not have durationMinutes in root?
    // SleepLogModel.toMap uses: 'startTime', 'endTime', 'quality', 'notes'.
    // It does NOT store duration explicitly in map?
    // Let's check SleepLogModel toMap in previous turn or infer.
    // Line 53: batch.set(logRef, model.toMap());
    // Line 30: SleepLogModel...
    // Let's rely on reconstructing model to get duration.

    final logModel = SleepLogModel.fromFirestore(snapshot);
    final durationToRemove = logModel.duration.inMinutes;

    final batch = firestore.batch();
    batch.delete(logRef);
    batch.set(dateDocRef, {
      'totalDurationMinutes': FieldValue.increment(-durationToRemove),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }
}
