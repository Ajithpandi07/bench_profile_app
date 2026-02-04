import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/sleep_log.dart';

class SleepLogModel extends SleepLog {
  const SleepLogModel({
    required super.id,
    required super.startTime,
    required super.endTime,
    required super.quality,
    super.remSleep,
    super.deepSleep,
    super.lightSleep,
    super.awakeSleep,
    super.notes,
  });

  factory SleepLogModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return SleepLogModel(
      id: doc.id,
      startTime: (data['start_time'] as Timestamp).toDate(),
      endTime: (data['end_time'] as Timestamp).toDate(),
      quality: data['quality'] ?? 0,
      remSleep: data['rem_sleep_seconds'] != null
          ? Duration(seconds: data['rem_sleep_seconds'])
          : null,
      deepSleep: data['deep_sleep_seconds'] != null
          ? Duration(seconds: data['deep_sleep_seconds'])
          : null,
      lightSleep: data['light_sleep_seconds'] != null
          ? Duration(seconds: data['light_sleep_seconds'])
          : null,
      awakeSleep: data['awake_sleep_seconds'] != null
          ? Duration(seconds: data['awake_sleep_seconds'])
          : null,
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'quality': quality,
      'rem_sleep_seconds': remSleep?.inSeconds,
      'deep_sleep_seconds': deepSleep?.inSeconds,
      'light_sleep_seconds': lightSleep?.inSeconds,
      'awake_sleep_seconds': awakeSleep?.inSeconds,
      'notes': notes,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}
