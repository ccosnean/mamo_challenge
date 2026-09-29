import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/api/api_failure.dart';
import 'package:payments_app/core/async/latest_value.dart';
import 'package:payments_app/features/auth/data/dto/auth_dtos.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

typedef _Session = ({String accessToken, User user});

/// Signs in with the OAuth password grant and holds the session.
///
/// It is also the [AccessTokenProvider] behind `AuthTokenInterceptor`, so
/// the token never leaves the data layer. The session lives in memory only;
/// a production app would keep a refresh token in the platform keystore
/// (e.g. `flutter_secure_storage`).
final class AuthRepositoryImpl implements AuthRepository, AccessTokenProvider {
  AuthRepositoryImpl(this._dio);

  static final Logger _log = Logger('AuthRepository');

  final Dio _dio;
  final LatestValue<_Session?> _session = LatestValue(null);

  @override
  Stream<User?> watchCurrentUser() =>
      _session.stream.map((session) => session?.user).distinct();

  @override
  String? get accessToken => _session.value?.accessToken;

  @override
  Stream<String?> watchAccessToken() =>
      _session.stream.map((session) => session?.accessToken).distinct();

  @override
  Future<User> signIn({
    required String username,
    required String password,
  }) async {
    _log.info('Sign-in: requesting a token (password grant)');
    try {
      final tokenResponse = await _dio.post<Map<String, dynamic>>(
        '/oauth/token',
        data: {
          'grant_type': 'password',
          'username': username,
          'password': password,
        },
      );
      final tokens = TokenResponseDto.fromJson(tokenResponse.data!);
      // The token itself is a credential: the log redactor masks it.
      _log.fine(
        'Token granted: ${tokens.tokenType} ${tokens.accessToken}, '
        'expires in ${tokens.expiresIn ~/ 60} min',
      );

      final meResponse = await _dio.get<Map<String, dynamic>>(
        '/me',
        options: Options(
          headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
        ),
      );
      final user = UserDto.fromJson(meResponse.data!).toDomain();

      _session.value = (accessToken: tokens.accessToken, user: user);
      _log.info('Signed in ${user.id}');
      return user;
    } on DioException catch (error) {
      final failure = ApiFailure.from(error);
      if (failure.code == 'invalid_grant') {
        _log.warning('Sign-in refused: invalid credentials');
        throw const InvalidCredentialsException();
      }
      _log.warning('Sign-in failed: $failure');
      throw const AuthUnavailableException();
    }
  }

  @override
  Future<void> signOut() async {
    final token = accessToken;
    if (token == null) return;
    // Local first: the app leaves protected screens immediately, even if the
    // server can't be reached.
    _session.value = null;
    _log.info('Signed out; revoking the token');
    try {
      await _dio.post<void>('/oauth/revoke', data: {'token': token});
      _log.fine('Token revoked');
    } on DioException catch (error) {
      _log.warning('Token revocation failed: ${ApiFailure.from(error)}');
    }
  }

  @override
  void invalidate() {
    if (_session.value == null) return;
    _session.value = null;
    _log.warning('Session ended by the server (401)');
  }

  Future<void> dispose() => _session.close();
}
