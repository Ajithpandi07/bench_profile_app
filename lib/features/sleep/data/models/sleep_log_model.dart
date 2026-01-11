import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sleep_log.dart';

class SleepLogModel extends SleepLog {
  const SleepLogModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.quality,
    super.notes,
  });

  factory SleepLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SleepLogModel(
      id: doc.id,
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      quality: data['quality'] ?? 0,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'quality': quality,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
