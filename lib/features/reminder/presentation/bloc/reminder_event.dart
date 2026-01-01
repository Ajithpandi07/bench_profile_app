import 'package:equatable/equatable.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object?> get props => [];
}

class LoadReminders extends ReminderEvent {
  final DateTime? selectedDate;

  const LoadReminders({this.selectedDate});

  @override
  List<Object?> get props => [selectedDate];
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
      ];
}

class DeleteReminder extends ReminderEvent {
  final String id;

  const DeleteReminder(this.id);

  @override
  List<Object?> get props => [id];
}
