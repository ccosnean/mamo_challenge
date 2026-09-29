import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/app/routes.dart';
import 'package:payments_app/core/device_auth/device_authenticator.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/approval/presentation/approval_bloc.dart';
import 'package:payments_app/features/approval/presentation/approval_queue_cubit.dart';
import 'package:payments_app/features/approval/presentation/approval_sheet.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';

/// Shows the approval sheet over whatever the user is doing, whenever a new
/// request arrives, and when they tap a pending request.
///
/// - One sheet, with every pending request as a page. Requests that arrive
///   while it's open join it as new pages.
/// - A request swiped away stays pending (in "Waiting for you") and isn't
///   pushed again.
/// - When the sheet closes, having approved anything goes to Payments,
///   where the payments now sit on top. Rejections alone leave the user
///   where they were.
///
/// Mount via `MaterialApp.builder`, below the app's bloc providers. Pages
/// reach it with [ApprovalLauncher.of].
class ApprovalCoordinator extends StatefulWidget {
  const ApprovalCoordinator({
    required this.navigatorKey,
    required this.router,
    required this.payments,
    required this.accounts,
    required this.authenticator,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GoRouter router;
  final PaymentsRepository payments;
  final AccountRepository accounts;
  final DeviceAuthenticator authenticator;
  final Widget child;

  @override
  State<ApprovalCoordinator> createState() => _ApprovalCoordinatorState();
}

class _ApprovalCoordinatorState extends State<ApprovalCoordinator> {
  static final Logger _log = Logger('ApprovalCoordinator');

  /// Requests already shown once, so a dismissed one isn't pushed again.
  final Set<PaymentId> _announced = {};
  bool _showing = false;

  void _onPending(List<PaymentRequest> pending) {
    // While the sheet is open, new requests join it as pages: they count as
    // announced, and never open a second sheet.
    if (_showing) {
      _announced.addAll(pending.map((r) => r.id));
      return;
    }
    final next = pending.where((r) => !_announced.contains(r.id)).firstOrNull;
    if (next != null) unawaited(_show(pending, startAt: next));
  }

  /// Opens the sheet on [request] (e.g. tapped in the pending list), with
  /// every other pending request one swipe away.
  void review(PaymentRequest request) {
    if (_showing) return;
    unawaited(
      _show(context.read<PendingRequestsCubit>().state, startAt: request),
    );
  }

  Future<void> _show(
    List<PaymentRequest> pending, {
    required PaymentRequest startAt,
  }) async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    final pages = pending.any((r) => r.id == startAt.id)
        ? pending
        : [...pending, startAt];

    _announced.addAll(pages.map((r) => r.id));
    _showing = true;
    _log.info(
      'Sheet opened on ${startAt.reference} (${pages.length} request(s))',
    );

    final result = await showModalBottomSheet<ApprovalQueueResult>(
      context: navigatorContext,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (_) => BlocProvider(
        create: (_) => ApprovalQueueCubit(
          payments: widget.payments,
          accounts: widget.accounts,
          authenticator: widget.authenticator,
          pending: pages,
          initial: startAt.id,
        ),
        child: const ApprovalSheet(),
      ),
    );

    _showing = false;
    if (!mounted) return;
    _log.info(
      result == null
          ? 'Sheet dismissed; undecided requests stay pending'
          : 'Sheet closed: ${result.outcomes.map((o) => o.name).join(', ')}',
    );

    if (result != null) {
      if (result.anyApproved) widget.router.go(AppRoutes.payments);
      final expired = result.count(ApprovalOutcome.expired);
      final handled = result.count(ApprovalOutcome.alreadyDecided);
      if (expired > 0) {
        _toast(
          expired == 1
              ? 'A request expired before it was decided.'
              : '$expired requests expired before they were decided.',
        );
      } else if (handled > 0) {
        _toast('A request was already handled elsewhere.');
      }
    }

    // Anything that arrived as the sheet closed opens next.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onPending(context.read<PendingRequestsCubit>().state);
    });
  }

  void _toast(String message) {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (navigatorContext == null) return;
    ScaffoldMessenger.maybeOf(navigatorContext)?.showSnackBar(
      SnackBar(
        content: Text(message, style: AppText.bodyMedium(Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PendingRequestsCubit, List<PaymentRequest>>(
      listener: (context, pending) => _onPending(pending),
      child: ApprovalLauncher._(state: this, child: widget.child),
    );
  }
}

/// Lets pages open the approval sheet for a pending request.
class ApprovalLauncher extends InheritedWidget {
  const ApprovalLauncher._({
    required _ApprovalCoordinatorState state,
    required super.child,
  }) : _state = state;

  final _ApprovalCoordinatorState _state;

  /// For event handlers: doesn't make the caller rebuild with it.
  static ApprovalLauncher of(BuildContext context) {
    final launcher = context.getInheritedWidgetOfExactType<ApprovalLauncher>();
    assert(launcher != null, 'No ApprovalCoordinator above this context');
    return launcher!;
  }

  void review(PaymentRequest request) => _state.review(request);

  @override
  bool updateShouldNotify(ApprovalLauncher oldWidget) =>
      !identical(_state, oldWidget._state);
}
