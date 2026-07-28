/// Centralized failure types. Repositories catch raw errors (Postgrest,
/// network, storage) and rethrow one of these so presentation code never
/// depends on backend SDK exception classes.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause});

  /// Human-readable, safe to show in a snackbar or error state.
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends AppException {
  const NetworkException({Object? cause})
      : super('No connection. Check your network and try again.', cause: cause);
}

class AuthException extends AppException {
  const AuthException(super.message, {super.cause});
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found']);
}

class PermissionDeniedException extends AppException {
  const PermissionDeniedException(
      [super.message = 'You do not have access to this']);
}

class ValidationException extends AppException {
  const ValidationException(super.message);
}

class ServerException extends AppException {
  const ServerException({Object? cause})
      : super('Something went wrong on our side. Try again in a moment.',
            cause: cause);
}

class OfflineDataException extends AppException {
  const OfflineDataException()
      : super('You are offline and this has not been cached yet.');
}
