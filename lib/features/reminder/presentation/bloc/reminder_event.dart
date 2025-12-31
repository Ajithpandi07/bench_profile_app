import 'package:equatable/equatable.dart';

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();

  @override
  List<Object> get props => [];
}

class LoadReminders extends ReminderEvent {}

class AddReminder extends ReminderEvent {
  final String name;
  final String category;
  final String quantity;
  final String unit;
  final String scheduleType;
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;

  const AddReminder({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.scheduleType,
    required this.startDate,
    required this.endDate,
    required this.smartReminder,
  });

  @override
  List<Object> get props => [
        name,
        category,
        quantity,
        unit,
        scheduleType,
        startDate,
        endDate,
        smartReminder,
      ];
}
