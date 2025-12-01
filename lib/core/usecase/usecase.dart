// lib/core/usecase/usecase.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

class DateParams extends Equatable {
  final DateTime date;
  const DateParams(this.date);

  @override
  List<Object?> get props => [date];
}
