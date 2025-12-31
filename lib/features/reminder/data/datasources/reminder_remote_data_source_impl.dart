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
  Stream<List<ReminderModel>> getReminders() {
    try {
      final user = _auth.currentUser;
      if (user == null) return const Stream.empty();

      return _firestore
          .collection('bench_profile')
          .doc(user.uid)
          .collection('userreminders')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => ReminderModel.fromSnapshot(doc))
            .toList();
      });
    } catch (e) {
      print('Error in getReminders: $e');
      return const Stream.empty();
    }
  }
}
