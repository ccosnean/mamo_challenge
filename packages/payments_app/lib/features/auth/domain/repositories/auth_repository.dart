import 'package:payments_app/features/auth/domain/models/user.dart';

/// The user's session.
abstract interface class AuthRepository {
  /// The signed-in user, or null when signed out. Emits the current value on
  /// listen.
  Stream<User?> watchCurrentUser();

  /// Throws `InvalidCredentialsException` for a wrong username or password.
  Future<User> signIn({required String username, required String password});

  /// Ends the session locally at once, then revokes the token on the server.
  Future<void> signOut();
}

/// Supplies the current access token to the other repositories, which
/// attach it to every request.
abstract interface class AccessTokenProvider {
  /// The current access token, or null when signed out.
  String? get accessToken;

  /// Emits the current token on listen and whenever it changes.
  Stream<String?> watchAccessToken();

  /// The server rejected the token (expired or revoked): drop the session so
  /// the user is sent back to sign in.
  void invalidate();
}
