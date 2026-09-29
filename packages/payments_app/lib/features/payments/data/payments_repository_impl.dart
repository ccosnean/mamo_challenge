import 'dart:async';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/core/api/api_failure.dart';
import 'package:payments_app/core/api/json_list.dart';
import 'package:payments_app/core/async/latest_value.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/payments/data/dto/payment_dtos.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

/// [PaymentsRepository] over the payments API, with an in-memory cache every
/// screen reads from.
///
/// - While signed in, pending requests are polled every [pollInterval]; that
///   is how new requests arrive.
/// - A decision updates the cache at once (the payment moves to the top of
///   the history, the request leaves the inbox), then re-reads history,
///   inbox and balances from the server to confirm.
/// - Everything is cleared on sign-out.
final class PaymentsRepositoryImpl implements PaymentsRepository {
  PaymentsRepositoryImpl({
    required Dio dio,
    required AccessTokenProvider tokens,
    required AccountRepository accounts,
    this.pollInterval = const Duration(seconds: 5),
  }) : _dio = dio,
       _tokens = tokens,
       _accounts = accounts {
    _sessionSubscription = tokens.watchAccessToken().listen(_onSession);
  }

  static final Logger _log = Logger('PaymentsRepository');

  final Duration pollInterval;
  final Dio _dio;
  final AccessTokenProvider _tokens;
  final AccountRepository _accounts;

  /// Null until the first load.
  final LatestValue<List<PaymentRequest>?> _pending = LatestValue(null);
  final LatestValue<List<Payment>?> _payments = LatestValue(null);
  late final StreamSubscription<String?> _sessionSubscription;
  Timer? _poll;

  @override
  Stream<List<PaymentRequest>> watchPendingRequests() =>
      _pending.stream.where((p) => p != null).cast<List<PaymentRequest>>();

  @override
  Stream<List<Payment>> watchPayments() =>
      _payments.stream.where((p) => p != null).cast<List<Payment>>();

  @override
  Future<void> refresh() async {
    await Future.wait([_refreshPending(), _refreshPayments()]);
  }

  @override
  Future<Payment> approve(PaymentId id, {required String fromAccountId}) =>
      _decide(
        id,
        'approve',
        body: {'debtor_account_id': fromAccountId},
      );

  @override
  Future<Payment> reject(PaymentId id) => _decide(id, 'reject');

  Future<void> dispose() async {
    _poll?.cancel();
    await _sessionSubscription.cancel();
    await _pending.close();
    await _payments.close();
  }

  void _onSession(String? token) {
    _poll?.cancel();
    if (token == null) {
      _pending.value = const [];
      _payments.value = const [];
      _log.fine('Signed out: polling stopped, caches cleared');
      return;
    }
    _log.info('Signed in: loading, polling every ${pollInterval.inSeconds} s');
    unawaited(refresh());
    _poll = Timer.periodic(pollInterval, (_) => unawaited(_refreshPending()));
  }

  Future<Payment> _decide(
    PaymentId id,
    String action, {
    Map<String, Object?>? body,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/payment-requests/${Uri.encodeComponent(id.value)}/$action',
        data: body,
      );
      final payment = PaymentDto.fromJson(response.data!).toDomain();
      _applyDecision(payment);
      final from = payment.debtorAccountId;
      _log.info(
        '${payment.reference} ${payment.status.name}: ${payment.amount}'
        '${from == null ? '' : ' from $from'}',
      );
      unawaited(refresh());
      if (payment.status.isApproved) unawaited(_accounts.refresh());
      return payment;
    } on DioException catch (error) {
      final failure = ApiFailure.from(error);
      _log.warning('$action ${id.value} failed: $failure');
      final mapped = _map(failure, id);
      // The inbox is out of date for these: re-read it.
      if (mapped is PaymentRequestExpiredException ||
          mapped is PaymentRequestNotFoundException ||
          mapped is PaymentAlreadyDecidedException) {
        unawaited(_refreshPending());
      }
      throw mapped;
    }
  }

  /// Shows a decision everywhere immediately, before the confirming reads.
  void _applyDecision(Payment payment) {
    final pending = _pending.value ?? const <PaymentRequest>[];
    _pending.value = List.unmodifiable(
      pending.where((r) => r.id != payment.id),
    );
    final history = _payments.value ?? const <Payment>[];
    _payments.value = List.unmodifiable(
      <Payment>[payment, ...history.where((p) => p.id != payment.id)]
        ..sort((a, b) => b.decidedAt.compareTo(a.decidedAt)),
    );
  }

  Future<void> _refreshPending() async {
    final before = {
      for (final r in _pending.value ?? const <PaymentRequest>[]) r.id,
    };
    await _load(
      '/payment-requests',
      fromJson: PaymentRequestDto.fromJson,
      toDomain: (dto) => dto.toDomain(),
      into: _pending,
    );
    final now = _pending.value ?? const <PaymentRequest>[];
    for (final request in now.where((r) => !before.contains(r.id))) {
      // Amounts are masked by the log redactor; the payee is never logged.
      _log.info(
        'New request ${request.reference}: ${request.amount}, '
        'expires ${request.expiresAt.toIso8601String()}',
      );
    }
    final gone = before.length - now.where((r) => before.contains(r.id)).length;
    if (gone > 0) _log.fine('$gone request(s) left the inbox');
  }

  Future<void> _refreshPayments() async {
    await _load(
      '/payments',
      fromJson: PaymentDto.fromJson,
      toDomain: (dto) => dto.toDomain(),
      into: _payments,
    );
    _log.fine('History: ${_payments.value?.length ?? 0} payments');
  }

  Future<void> _load<D, T>(
    String path, {
    required D Function(Map<String, dynamic>) fromJson,
    required T Function(D) toDomain,
    required LatestValue<List<T>?> into,
  }) async {
    final token = _tokens.accessToken;
    if (token == null) return;
    try {
      final response = await _dio.get<Map<String, dynamic>>(path);
      // Never show one session's data in another.
      if (_tokens.accessToken != token) return;
      into.value = parseDataList(
        response.data,
        fromJson: fromJson,
        toDomain: toDomain,
        log: _log,
      );
    } on DioException catch (error) {
      // Keep the last known data; the next poll or refresh retries.
      _log.warning('GET $path failed: ${ApiFailure.from(error)}');
    }
  }

  static PaymentsException _map(ApiFailure failure, PaymentId id) =>
      switch (failure) {
        ApiFailure(status: 401) => const PaymentsUnauthorizedException(),
        ApiFailure(status: 404) => PaymentRequestNotFoundException(id),
        ApiFailure(status: 409) => PaymentAlreadyDecidedException(id),
        ApiFailure(status: 410) => PaymentRequestExpiredException(id),
        ApiFailure(status: 422) => InsufficientFundsException(id),
        _ => const PaymentsUnavailableException(),
      };
}
