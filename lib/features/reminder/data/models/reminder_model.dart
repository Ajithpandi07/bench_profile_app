import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/reminder.dart';

class ReminderModel extends Reminder {
  const ReminderModel({
    required super.id,
    required super.name,
    required super.category,
    required super.quantity,
    required super.unit,
    required super.scheduleType,
    super.daysOfWeek,
    super.dayOfMonth,
    super.time,
    required super.startDate,
    required super.endDate,
    super.smartReminder = false,
    super.isCompleted = false,
    super.createdAt,
    super.updatedAt,
  });

  factory ReminderModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReminderModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      quantity: data['quantity'] ?? '',
      unit: data['unit'] ?? '',
      scheduleType: data['scheduleType'] ?? '',
      daysOfWeek: (data['daysOfWeek'] as List<dynamic>?)?.cast<int>(),
      dayOfMonth: data['dayOfMonth'] as int?,
      time: data['time'] as String?,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      smartReminder: data['smartReminder'] is bool
          ? data['smartReminder']
          : data['smartReminder'].toString().toLowerCase() == 'true',
      isCompleted: data['isCompleted'] is bool
          ? data['isCompleted']
          : data['isCompleted'].toString().toLowerCase() == 'true',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'scheduleType': scheduleType,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'time': time,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'smartReminder': smartReminder,
      'isCompleted': isCompleted,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static ReminderModel fromEntity(Reminder reminder) {
    return ReminderModel(
      id: reminder.id,
      name: reminder.name,
      category: reminder.category,
      quantity: reminder.quantity,
      unit: reminder.unit,
      scheduleType: reminder.scheduleType,
      daysOfWeek: reminder.daysOfWeek,
      dayOfMonth: reminder.dayOfMonth,
      time: reminder.time,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      smartReminder: reminder.smartReminder,
      isCompleted: reminder.isCompleted,
      createdAt: reminder.createdAt,
      updatedAt: reminder.updatedAt,
    );
  }

  Reminder toEntity() {
    return Reminder(
      id: id,
      name: name,
      category: category,
      quantity: quantity,
      unit: unit,
      scheduleType: scheduleType,
      daysOfWeek: daysOfWeek,
      dayOfMonth: dayOfMonth,
      time: time,
      startDate: startDate,
      endDate: endDate,
      smartReminder: smartReminder,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  ReminderModel copyWith({
    String? id,
    String? name,
    String? category,
    String? quantity,
    String? unit,
    String? scheduleType,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    String? time,
    DateTime? startDate,
    DateTime? endDate,
    bool? smartReminder,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      scheduleType: scheduleType ?? this.scheduleType,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      time: time ?? this.time,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      smartReminder: smartReminder ?? this.smartReminder,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
