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
  final DateTime startDate;
  final DateTime endDate;
  final bool smartReminder;

  final bool isCompleted;

  const Reminder({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.scheduleType,
    required this.startDate,
    required this.endDate,
    this.smartReminder = false,
    this.isCompleted = false,
  });

  @override
  List<Object> get props => [
        id,
        name,
        category,
        quantity,
        unit,
        scheduleType,
        startDate,
        endDate,
        smartReminder,
        isCompleted,
      ];
}
