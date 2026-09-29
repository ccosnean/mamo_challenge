import 'package:equatable/equatable.dart';
import 'package:payments_app/features/auth/domain/models/company.dart';

/// The signed-in person, acting for [company].
final class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.company,
  });

  final String id;

  /// Login name, e.g. `layla.haddad`.
  final String username;

  /// Full name, e.g. `Layla Haddad`.
  final String name;

  final Company company;

  @override
  List<Object> get props => [id, username, name, company];

  /// Names are personal data, so they are kept out of logs and crash reports.
  @override
  String toString() => 'User(id: $id, name: <redacted>, company: $company)';
}
