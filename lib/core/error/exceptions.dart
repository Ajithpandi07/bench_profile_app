// lib/core/error/exceptions.dart

class ServerException implements Exception {

  final String message;

  ServerException(this.message);
}

class CacheException implements Exception {
  final String message;

  CacheException([this.message = 'Cache Exception']);
}

class PermissionDeniedException implements Exception {}