import 'package:equatable/equatable.dart';

abstract class HydrationState extends Equatable {
  const HydrationState();

  @override
  List<Object> get props => [];
}

class HydrationInitial extends HydrationState {}

class HydrationSaving extends HydrationState {}

class HydrationSuccess extends HydrationState {}

class HydrationFailure extends HydrationState {
  final String message;

  const HydrationFailure(this.message);

  @override
  List<Object> get props => [message];
}
