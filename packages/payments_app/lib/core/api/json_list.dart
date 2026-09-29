import 'package:logging/logging.dart';

/// Parses a `{"data": [...]}` envelope into domain objects.
///
/// An item that doesn't parse or fails validation is dropped and logged
/// (severe), so one bad record can't take the whole screen down. A body
/// that isn't an envelope at all throws a [FormatException].
List<T> parseDataList<D, T>(
  Object? body, {
  required D Function(Map<String, dynamic> json) fromJson,
  required T Function(D dto) toDomain,
  required Logger log,
}) {
  final data = body is Map<String, dynamic> ? body['data'] : null;
  if (data is! List) {
    throw const FormatException('Expected a {"data": [...]} response');
  }
  final items = <T>[];
  for (final (index, item) in data.indexed) {
    try {
      items.add(toDomain(fromJson(item as Map<String, dynamic>)));
    } on Object catch (error) {
      log.severe('Dropped malformed item #$index', error);
    }
  }
  return List.unmodifiable(items);
}
