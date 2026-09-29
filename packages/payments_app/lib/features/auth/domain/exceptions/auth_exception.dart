/// Authentication failures. Sealed so callers handle every case.
sealed class AuthException implements Exception {
  const AuthException();
}

/// Wrong username or password (OAuth `invalid_grant`).
final class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException();

  @override
  String toString() => 'InvalidCredentialsException()';
}

/// The sign-in service couldn't be reached or failed. Safe to retry.
final class AuthUnavailableException extends AuthException {
  const AuthUnavailableException();

  @override
  String toString() => 'AuthUnavailableException()';
}
