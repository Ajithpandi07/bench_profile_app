import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reminder.dart';

class ReminderModel extends Reminder {
  const ReminderModel({
    required String id,
    required String name,
    required String category,
    required String quantity,
    required String unit,
    required String scheduleType,
    required DateTime startDate,
    required DateTime endDate,
    bool smartReminder = false,
    bool isCompleted = false,
  }) : super(
          id: id,
          name: name,
          category: category,
          quantity: quantity,
          unit: unit,
          scheduleType: scheduleType,
          startDate: startDate,
          endDate: endDate,
          smartReminder: smartReminder,
          isCompleted: isCompleted,
        );

  factory ReminderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? '',
      unit: data['unit'] ?? '',
      scheduleType: data['scheduleType'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      smartReminder: data['smartReminder'] is bool
          ? data['smartReminder']
          : data['smartReminder'].toString().toLowerCase() == 'true',
      isCompleted: data['isCompleted'] is bool
          ? data['isCompleted']
          : data['isCompleted'].toString().toLowerCase() == 'true',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'scheduleType': scheduleType,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'smartReminder': smartReminder,
      'isCompleted': isCompleted,
    };
  }
}
