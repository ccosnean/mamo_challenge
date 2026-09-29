import 'package:equatable/equatable.dart';

/// The business the user is signed in to. Accounts belong to it.
final class Company extends Equatable {
  const Company({required this.id, required this.name});

  final String id;

  /// Registered name, e.g. `Palmline Studio FZ-LLC`.
  final String name;

  @override
  List<Object> get props => [id, name];

  @override
  String toString() => 'Company(id: $id)';
}
