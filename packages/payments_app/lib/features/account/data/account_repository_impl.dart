import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/api/api_failure.dart';
import 'package:payments_app/core/api/json_list.dart';
import 'package:payments_app/core/async/latest_value.dart';
import 'package:payments_app/features/account/data/dto/account_dto.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/auth/domain/domain.dart';

/// [AccountRepository] over `GET /accounts`, with an in-memory cache every
/// screen reads from. Loads on sign-in, re-reads every [pollInterval] while
/// signed in (balances change server-side: incoming money, other devices),
/// clears on sign-out.
final class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl({
    required Dio dio,
    required AccessTokenProvider tokens,
    this.pollInterval = const Duration(seconds: 5),
  }) : _dio = dio,
       _tokens = tokens {
    _sessionSubscription = tokens.watchAccessToken().listen((token) {
      _poll?.cancel();
      if (token == null) {
        _accounts.value = const [];
        _log.fine('Signed out: polling stopped, accounts cleared');
      } else {
        unawaited(refresh());
        _poll = Timer.periodic(pollInterval, (_) => unawaited(refresh()));
      }
    });
  }

  final Duration pollInterval;
  Timer? _poll;

  static final Logger _log = Logger('AccountRepository');

  final Dio _dio;
  final AccessTokenProvider _tokens;

  /// Null until the first load.
  final LatestValue<List<Account>?> _accounts = LatestValue(null);
  late final StreamSubscription<String?> _sessionSubscription;

  @override
  Stream<List<Account>> watchAccounts() =>
      _accounts.stream.where((a) => a != null).cast<List<Account>>();

  @override
  Future<void> refresh() async {
    final token = _tokens.accessToken;
    if (token == null) return;
    try {
      final response = await _dio.get<Map<String, dynamic>>('/accounts');
      // The session may have changed while waiting: never show one
      // session's data in another.
      if (_tokens.accessToken != token) return;
      final accounts = parseDataList(
        response.data,
        fromJson: AccountDto.fromJson,
        toDomain: (dto) => dto.toDomain(),
        log: _log,
      );
      // Polling mostly finds nothing new: only report actual changes.
      if (_sameAs(accounts)) return;
      _accounts.value = accounts;
      _log.info(
        'Loaded ${accounts.length} accounts, '
        'total ${totalAvailableBalance(accounts)}',
      );
      for (final account in accounts) {
        // IBANs and balances are masked by the log redactor.
        _log.fine(
          '${account.id}: ${account.iban.value}, '
          'available ${account.availableBalance}',
        );
      }
    } on DioException catch (error) {
      // Keep showing the last known balances; the next refresh retries.
      _log.warning('Refresh failed: ${ApiFailure.from(error)}');
    }
  }

  bool _sameAs(List<Account> accounts) {
    final current = _accounts.value;
    if (current == null || current.length != accounts.length) return false;
    for (var i = 0; i < accounts.length; i++) {
      if (current[i] != accounts[i]) return false;
    }
    return true;
  }

  Future<void> dispose() async {
    _poll?.cancel();
    await _sessionSubscription.cancel();
    await _accounts.close();
  }
}
