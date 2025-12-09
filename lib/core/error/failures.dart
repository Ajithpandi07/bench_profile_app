/// Simple failure type used across the domain layer.
class Failure {
  final String message;
  const Failure(this.message);
  @override
  String toString() => 'Failure: $message';
}

class ServerFailure extends Failure { const ServerFailure(super.message); }

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
