import 'package:equatable/equatable.dart';

class Reminder extends Equatable {
  final String id;
  // Previously 'title'
  final String name;
  // Previously 'description' - reused or kept if needed.
  // User asked for "reminder name", "category", "Quantity", "unit".
  // Description might be redundant but I will keep it as optional or remove if strictly following new spec.
  // I will keep description as optional/reused for now, but focus on new fields.
  final String category;
  final String quantity;
  final String unit;

  // Schedule
  final String scheduleType; // Daily, Weekly, Monthly, As Needed
  final List<int>? daysOfWeek; // 1 = Monday, 7 = Sunday
  final int? dayOfMonth; // 1-31
  final String? time;
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;
  final bool isCompleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Custom Schedule
  final int? interval;
  final String? customFrequency;
  final String? recurrenceEndType;
  final int? recurrenceCount;
  final List<DateTime>? skippedDates;

  const Reminder({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.scheduleType,
    this.daysOfWeek,
    this.dayOfMonth,
    this.time,
    required this.startDate,
    required this.endDate,
    this.smartReminder = false,
    this.isCompleted = false,
    this.createdAt,
    this.updatedAt,
    this.interval,
    this.customFrequency,
    this.recurrenceEndType,
    this.recurrenceCount,
    this.skippedDates,
  });

  Reminder copyWith({
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
    int? interval,
    String? customFrequency,
    String? recurrenceEndType,
    int? recurrenceCount,
    List<DateTime>? skippedDates,
  }) {
    return Reminder(
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
      interval: interval ?? this.interval,
      customFrequency: customFrequency ?? this.customFrequency,
      recurrenceEndType: recurrenceEndType ?? this.recurrenceEndType,
      recurrenceCount: recurrenceCount ?? this.recurrenceCount,
      skippedDates: skippedDates ?? this.skippedDates,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    quantity,
    unit,
    scheduleType,
    daysOfWeek,
    dayOfMonth,
    time,
    startDate,
    endDate,
    smartReminder,
    isCompleted,
    createdAt,
    updatedAt,
    interval,
    customFrequency,
    recurrenceEndType,
    recurrenceCount,
    skippedDates,
  ];
}
