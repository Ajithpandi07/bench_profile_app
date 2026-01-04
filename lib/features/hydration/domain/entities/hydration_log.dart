import 'package:equatable/equatable.dart';

class HydrationLog extends Equatable {
  final String id;
  final double amountLiters;
  final DateTime timestamp;
  final String beverageType; // 'Regular', 'Carbonated', etc.
  final String userId;

  const HydrationLog({
    required this.id,
    required this.amountLiters,
    required this.timestamp,
    required this.beverageType,
    required this.userId,
  });

  @override
  List<Object> get props => [id, amountLiters, timestamp, beverageType, userId];
}
