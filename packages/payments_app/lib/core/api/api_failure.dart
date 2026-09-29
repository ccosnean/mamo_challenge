import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

/// A failed API call, reduced to what repositories decide on: the HTTP
/// status and the API's error code, or that the network itself failed.
@immutable
final class ApiFailure {
  const ApiFailure({this.status, this.code, this.network = false});

  factory ApiFailure.from(DioException exception) {
    final body = exception.response?.data;
    return ApiFailure(
      status: exception.response?.statusCode,
      code: body is Map && body['error'] is String
          ? body['error'] as String
          : null,
      network: switch (exception.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => true,
        _ => false,
      },
    );
  }

  final int? status;

  /// The API's machine-readable error, e.g. `insufficient_funds`.
  final String? code;

  /// No response at all (offline, timeout).
  final bool network;

  @override
  String toString() => network
      ? 'ApiFailure(network)'
      : 'ApiFailure(${status ?? '-'}${code == null ? '' : ' $code'})';
}
