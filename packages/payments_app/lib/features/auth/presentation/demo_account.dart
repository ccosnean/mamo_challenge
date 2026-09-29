import 'package:meta/meta.dart';

/// A demo user a host (the showcase) can hand the app, so the login screen
/// can describe them and sign in with one tap.
///
/// Production passes none, and the login screen asks for credentials.
@immutable
final class DemoAccount {
  const DemoAccount({
    required this.username,
    required this.password,
    required this.name,
    required this.companyName,
    this.role,
  });

  final String username;
  final String password;
  final String name;
  final String companyName;
  final String? role;

  /// Credentials: never printed.
  @override
  String toString() => 'DemoAccount(<redacted>)';
}
