import 'package:equatable/equatable.dart';

/// Simple failure type used across the domain layer.
class Failure extends Equatable {
  final String message;
  const Failure(this.message);
  @override
  String toString() => 'Failure: $message';

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class RepositoryFailure extends Failure {
  const RepositoryFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class HealthConnectFailure extends Failure {
  const HealthConnectFailure(super.message);
}
