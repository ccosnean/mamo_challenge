import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:mock_bank/src/mock_bank_server.dart';

/// Answers dio requests from a [MockBankServer] instead of the network.
///
/// Add it as the **last** interceptor, so the app's own interceptors (auth
/// header, logging) run first, exactly as they would against the real API.
/// Bodies cross the boundary as JSON text in both directions; responses
/// continue through the app's response and error interceptors.
final class MockBankInterceptor extends Interceptor {
  MockBankInterceptor(this.server);

  final MockBankServer server;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (server.offline) {
      await Future<void>.delayed(server.latency);
      handler.reject(
        DioException.connectionError(
          requestOptions: options,
          reason: 'Mock bank is offline',
        ),
        true,
      );
      return;
    }

    final response = await server.handle(
      MockHttpRequest(
        method: options.method.toUpperCase(),
        path: options.uri.path,
        headers: {
          for (final entry in options.headers.entries)
            entry.key.toLowerCase(): '${entry.value}',
        },
        body: switch (options.data) {
          null => null,
          final String text => text,
          final Object data => jsonEncode(data),
        },
      ),
    );

    final dioResponse = Response<Object?>(
      requestOptions: options,
      statusCode: response.status,
      data: jsonDecode(response.body),
      headers: Headers.fromMap({
        Headers.contentTypeHeader: [Headers.jsonContentType],
      }),
    );

    if (response.ok) {
      handler.resolve(dioResponse, true);
    } else {
      handler.reject(
        DioException.badResponse(
          statusCode: response.status,
          requestOptions: options,
          response: dioResponse,
        ),
        true,
      );
    }
  }
}
