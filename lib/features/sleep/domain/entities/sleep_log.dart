import 'package:equatable/equatable.dart';

class SleepLog extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final int quality; // 0-100
  final Duration? remSleep;
  final Duration? deepSleep;
  final Duration? lightSleep;
  final Duration? awakeSleep;
  final String? notes;

  const SleepLog({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.quality,
    this.remSleep,
    this.deepSleep,
    this.lightSleep,
    this.awakeSleep,
    this.notes,
  });

  Duration get duration => endTime.difference(startTime);

  @override
  List<Object?> get props => [
    id,
    startTime,
    endTime,
    quality,
    remSleep,
    deepSleep,
    lightSleep,
    awakeSleep,
    notes,
  ];
}
