import 'package:equatable/equatable.dart';
import '../../domain/entities/reminder.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminders extends ReminderEvent {
  final DateTime? selectedDate;
  final bool forceRefresh;

  const LoadReminders({this.selectedDate, this.forceRefresh = false});

  @override
  List<Object?> get props => [selectedDate, forceRefresh];
}

class AddReminder extends ReminderEvent {
  final String name;
  final String category;
  final String quantity;
  final String unit;
  final String scheduleType;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final String? time;
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;
  final int? interval;
  final String? customFrequency;
  final String? recurrenceEndType;
  final int? recurrenceCount;

  const AddReminder({
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
    required this.smartReminder,
    this.interval,
    this.customFrequency,
    this.recurrenceEndType,
    this.recurrenceCount,
  });

  @override
  List<Object?> get props => [
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
    interval,
    customFrequency,
    recurrenceEndType,
    recurrenceCount,
  ];
}

class UpdateReminder extends ReminderEvent {
  final String id;
  final String name;
  final String category;
  final String quantity;
  final String unit;
  final String scheduleType;
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final String? time;
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;
  final int? interval;
  final String? customFrequency;
  final String? recurrenceEndType;
  final int? recurrenceCount;

  const UpdateReminder({
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
    required this.smartReminder,
    this.interval,
    this.customFrequency,
    this.recurrenceEndType,
    this.recurrenceCount,
  });

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
    interval,
    customFrequency,
    recurrenceEndType,
    recurrenceCount,
  ];
}

class DeleteReminder extends ReminderEvent {
  final String id;

  const DeleteReminder(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleReminderForDate extends ReminderEvent {
  final Reminder reminder;
  final DateTime date;
  final bool isEnabled; // true = remove from skipped, false = add to skipped

  const ToggleReminderForDate({
    required this.reminder,
    required this.date,
    required this.isEnabled,
  });

  @override
  List<Object?> get props => [reminder, date, isEnabled];
}

class RescheduleAllNotifications extends ReminderEvent {}
