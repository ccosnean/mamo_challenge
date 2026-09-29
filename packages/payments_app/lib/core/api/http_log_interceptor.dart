import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

/// Logs each call as one line: method, path, status and duration.
///
/// Never logs headers or bodies: they carry tokens, names, IBANs and
/// amounts. Only the item count of list responses and the API's error code.
final class HttpLogInterceptor extends Interceptor {
  static final Logger _log = Logger('Http');
  static const String _startKey = 'http_log_start';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final data = response.data;
    final items = data is Map && data['data'] is List
        ? ', ${(data['data'] as List).length} items'
        : '';
    _log.fine(
      '${options.method} ${options.uri.path} → ${response.statusCode} '
      '(${_elapsed(options)} ms$items)',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final body = err.response?.data;
    final code = body is Map && body['error'] is String
        ? ' ${body['error']}'
        : '';
    final outcome =
        '${err.response?.statusCode?.toString() ?? err.type.name}$code';
    _log.warning(
      '${options.method} ${options.uri.path} → $outcome '
      '(${_elapsed(options)} ms)',
    );
    handler.next(err);
  }

  static int _elapsed(RequestOptions options) {
    final start = options.extra[_startKey];
    return start is DateTime
        ? DateTime.now().difference(start).inMilliseconds
        : 0;
  }
}
