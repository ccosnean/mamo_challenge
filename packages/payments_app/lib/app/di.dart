import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/app/app_config.dart';
import 'package:payments_app/core/api/http_log_interceptor.dart';
import 'package:payments_app/features/account/data/account_repository_impl.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/auth/data/auth_repository_impl.dart';
import 'package:payments_app/features/auth/data/auth_token_interceptor.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/payments/data/payments_repository_impl.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

final GetIt getIt = GetIt.instance;

final Logger _log = Logger('DI');

/// Composition root: the only place that picks concrete implementations.
Future<void> configureDependencies(AppConfig config) async {
  await getIt.reset();

  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );
  final auth = AuthRepositoryImpl(dio);
  dio.interceptors.addAll([
    AuthTokenInterceptor(auth),
    HttpLogInterceptor(),
    // Last, so the app's own interceptors run first, as against the real API.
    ...config.transportInterceptors,
  ]);
  final accounts = AccountRepositoryImpl(
    dio: dio,
    tokens: auth,
    pollInterval: config.pollInterval,
  );
  final payments = PaymentsRepositoryImpl(
    dio: dio,
    tokens: auth,
    accounts: accounts,
    pollInterval: config.pollInterval,
  );

  getIt
    ..registerSingleton<AppConfig>(config)
    ..registerSingleton<Dio>(dio, dispose: (dio) => dio.close())
    ..registerSingleton<AuthRepository>(
      auth,
      dispose: (_) => auth.dispose(),
    )
    ..registerSingleton<AccountRepository>(
      accounts,
      dispose: (_) => accounts.dispose(),
    )
    ..registerSingleton<PaymentsRepository>(
      payments,
      dispose: (_) => payments.dispose(),
    );

  _log.info('Dependencies configured');
}
