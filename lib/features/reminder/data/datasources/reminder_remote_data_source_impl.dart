import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reminder_remote_data_source.dart';
import '../models/reminder_model.dart';

class ReminderRemoteDataSourceImpl implements ReminderRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReminderRemoteDataSourceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> addReminder(ReminderModel reminder) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _firestore
        .collection('bench_profile')
        .doc(user.uid)
        .collection('userreminders')
        .add(reminder.toMap());
  }

  @override
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      if (reminder.id == null) {
        throw Exception('Reminder ID is null');
      }
      await _firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('userreminders')
          .doc(reminder.id)
          .update(reminder.toMap());
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');
      await _firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('userreminders')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  @override
  Future<List<ReminderModel>> fetchReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('userreminders')
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.now())
          .orderBy('endDate')
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      print('Error in fetchReminders: $e');
      return [];
    }
  }
}
