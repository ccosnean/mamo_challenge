import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

/// Attaches the session's access token to every API call, and ends the
/// session when the server rejects it.
///
/// OAuth endpoints are left alone (they authenticate differently), and so
/// is any request that already carries its own `Authorization` header.
final class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._tokens);

  static const String _header = 'Authorization';
  static final Logger _log = Logger('AuthToken');

  final AccessTokenProvider _tokens;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null &&
        !_isOAuth(options) &&
        !options.headers.containsKey(_header)) {
      options.headers[_header] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final sentWith = err.requestOptions.headers[_header];
    // Only the token this request carried is known to be dead: a response
    // to an older request must not end a newer session.
    if (err.response?.statusCode == 401 &&
        !_isOAuth(err.requestOptions) &&
        sentWith == 'Bearer ${_tokens.accessToken}') {
      _log.warning(
        '401 on ${err.requestOptions.uri.path}: token $sentWith rejected, '
        'ending the session',
      );
      _tokens.invalidate();
    }
    handler.next(err);
  }

  static bool _isOAuth(RequestOptions options) =>
      options.uri.path.startsWith('/oauth/');
}
