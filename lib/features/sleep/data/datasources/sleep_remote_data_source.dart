import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../models/sleep_log_model.dart';
import '../../domain/entities/sleep_log.dart';

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

  // Helper
  String _getDateId(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> logSleep(SleepLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final dateId = _getDateId(log.startTime);

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
        .doc(dateId)
        .collection('logs')
        .doc(docId);

    await logRef.set(model.toMap());
  }

  @override
  Future<List<SleepLog>> getSleepLogs(DateTime date) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final dateId = _getDateId(date);

    final snapshot = await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(dateId)
        .collection('logs')
        .orderBy('start_time')
        .get();

    return snapshot.docs
        .map((doc) => SleepLogModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<SleepLog>> getSleepLogsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    List<SleepLog> allLogs = [];
    // Iterate through days
    for (
      var d = start;
      d.isBefore(end) || d.isAtSameMomentAs(end);
      d = d.add(const Duration(days: 1))
    ) {
      final dateId = _getDateId(d);
      final snapshot = await firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('sleep_logs')
          .doc(dateId)
          .collection('logs')
          .get();

      final dayLogs = snapshot.docs
          .map((doc) => SleepLogModel.fromFirestore(doc))
          .toList();
      allLogs.addAll(dayLogs);

      // Safety break
      if (d.difference(end).inDays > 1000) break;
    }

    // Sort combined logs
    allLogs.sort((a, b) => a.startTime.compareTo(b.startTime));

    return allLogs;
  }

  @override
  Future<void> deleteSleepLog(SleepLog log) async {
    final user = auth.currentUser;
    if (user == null) throw ServerException('User is not authenticated');

    final dateId = _getDateId(log.startTime);

    await firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('sleep_logs')
        .doc(dateId)
        .collection('logs')
        .doc(log.id)
        .delete();
  }
}
