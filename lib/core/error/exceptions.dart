// lib/core/error/exceptions.dart

class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache Exception']);

  @override
  String toString() => 'CacheException: $message';
}

class PermissionDeniedException implements Exception {}

class HealthConnectNotInstalledException implements Exception {}
