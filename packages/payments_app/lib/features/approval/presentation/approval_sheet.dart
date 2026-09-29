import 'dart:async';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/format/masking.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/app_button.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/party_avatar.dart';
import 'package:payments_app/core/ui/widgets/pressable.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/approval/presentation/approval_bloc.dart';
import 'package:payments_app/features/approval/presentation/approval_queue_cubit.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

/// The approval bottom sheet: every pending request as a page, one unlock
/// for all of them. Swipe (or use the arrows and dots) between requests.
///
/// The header (queue position) and footer (actions) are pinned; only the
/// request's details scroll, and the footer stays clear of the home
/// indicator. Pops with an [ApprovalQueueResult] once every page is
/// decided; a swipe down leaves the rest pending.
class ApprovalSheet extends StatefulWidget {
  const ApprovalSheet({super.key});

  @override
  State<ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends State<ApprovalSheet> {
  late final AppLifecycleListener _lifecycle;

  /// +1 when moving to a later page, -1 to an earlier one: the slide
  /// direction of the page transition.
  int _direction = 1;

  @override
  void initState() {
    super.initState();
    // Revealed details must not sit in the app switcher.
    _lifecycle = AppLifecycleListener(
      onHide: () => context.read<ApprovalQueueCubit>().lock(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final queue = context.read<ApprovalQueueCubit>();
    final target = queue.state.index + delta;
    if (target < 0 || target >= queue.state.requests.length) return;
    setState(() => _direction = delta.sign);
    queue.showPage(target);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return BlocConsumer<ApprovalQueueCubit, ApprovalQueueState>(
      listenWhen: (previous, current) =>
          previous.outcomes.length != current.outcomes.length ||
          (!previous.finished && current.finished) ||
          previous.unlockNotice != current.unlockNotice,
      listener: (context, state) {
        if (state.unlockNotice != UnlockNotice.none) {
          unawaited(HapticFeedback.heavyImpact());
        }
        if (state.outcomes.isNotEmpty &&
            state.outcomes.last == ApprovalOutcome.approved) {
          unawaited(HapticFeedback.mediumImpact());
        }
        if (state.finished) {
          Navigator.of(context).pop(context.read<ApprovalQueueCubit>().result);
        }
      },
      builder: (context, state) {
        final request = state.current;
        final queue = context.read<ApprovalQueueCubit>();
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.outline,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (state.requests.length > 1) ...[
                    _QueueIndicator(
                      index: state.index,
                      count: state.requests.length,
                      onPrevious: () => _go(-1),
                      onNext: () => _go(1),
                      onSelect: (index) => _go(index - state.index),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            if (request != null)
              Flexible(
                // Mouse drags count too: the showcase runs in a browser.
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: PointerDeviceKind.values.toSet(),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity < -200) _go(1);
                        if (velocity > 200) _go(-1);
                      },
                      child: AnimatedSize(
                        duration: Motion.of(context, Motion.medium),
                        curve: Motion.standard,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: Motion.of(context, Motion.medium),
                          switchInCurve: Motion.standard,
                          transitionBuilder: (child, animation) {
                            final incoming = child.key == ValueKey(request.id);
                            final from = Offset(
                              (incoming ? 0.25 : -0.25) * _direction,
                              0,
                            );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween(
                                  begin: from,
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.topCenter,
                            children: [...previous, ?current],
                          ),
                          child: BlocProvider.value(
                            key: ValueKey(request.id),
                            value: queue.pageFor(request),
                            child: _RequestBody(queue: state),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (request != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
                  child: BlocProvider.value(
                    key: ValueKey(request.id),
                    value: queue.pageFor(request),
                    child: BlocBuilder<ApprovalBloc, ApprovalState>(
                      builder: (context, page) =>
                          _Actions(state: page, queue: state),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// "Request 2 of 4" with arrows and dots. Only shown for 2+ requests.
class _QueueIndicator extends StatelessWidget {
  const _QueueIndicator({
    required this.index,
    required this.count,
    required this.onPrevious,
    required this.onNext,
    required this.onSelect,
  });

  final int index;
  final int count;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      children: [
        _Arrow(
          icon: Icons.chevron_left_rounded,
          label: 'Previous request',
          onPressed: index > 0 ? onPrevious : null,
        ),
        Expanded(
          child: Column(
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'Request ${index + 1} of $count',
                  style: AppText.small(colors.muted),
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < count; i++)
                    Semantics(
                      button: true,
                      selected: i == index,
                      label: 'Request ${i + 1}',
                      excludeSemantics: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: AnimatedContainer(
                            duration: Motion.of(context, Motion.fast),
                            width: i == index ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? colors.accent
                                  : colors.outline,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _Arrow(
          icon: Icons.chevron_right_rounded,
          label: 'Next request',
          onPressed: index < count - 1 ? onNext : null,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: colors.fill,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 40,
            child: Icon(
              icon,
              color: onPressed == null ? colors.outline : colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// One request's details: masked while the sheet is locked, revealed once
/// unlocked. The actions live in the sheet's pinned footer.
class _RequestBody extends StatelessWidget {
  const _RequestBody({required this.queue});

  final ApprovalQueueState queue;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ApprovalBloc, ApprovalState>(
      builder: (context, state) => AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.standard,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.medium),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: state.revealed
              ? _RevealedBody(key: const ValueKey('revealed'), state: state)
              : _MaskedBody(
                  key: const ValueKey('masked'),
                  state: state,
                  unlockNotice: queue.unlockNotice,
                ),
        ),
      ),
    );
  }
}

class _MaskedBody extends StatelessWidget {
  const _MaskedBody({
    required this.state,
    required this.unlockNotice,
    super.key,
  });

  final ApprovalState state;
  final UnlockNotice unlockNotice;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final request = state.request;
    final notice = switch (unlockNotice) {
      UnlockNotice.failed =>
        'Face ID didn’t recognise you. The details stay hidden until you '
            'verify.',
      UnlockNotice.unavailable =>
        'Face ID isn’t available on this device, so the details can’t be '
            'revealed here.',
      UnlockNotice.none =>
        state.notice == ApprovalNotice.serviceUnavailable
            ? 'We couldn’t reach the bank. Nothing was sent. Try again.'
            : null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExpiryLabel(request: request),
        const SizedBox(height: 4),
        Semantics(
          header: true,
          child: Text(
            'Approve this payment?',
            style: AppText.heading(colors.ink),
          ),
        ),
        const SizedBox(height: 18),
        if (notice != null) ...[
          _Notice.error(notice),
          const SizedBox(height: 14),
        ],
        _InfoBlock(
          rows: [
            _InfoRow(
              label: 'To',
              value: _Locked(
                child: Text(
                  Masking.name(request.payee.name),
                  style: AppText.label(colors.ink),
                ),
              ),
              semanticValue: 'Recipient hidden',
            ),
            _InfoRow(
              label: 'Amount',
              value: _Locked(child: MoneyText(request.amount, masked: true)),
              semanticValue: 'Amount hidden',
            ),
            _InfoRow(
              label: 'Reference',
              value: Text(
                request.reference,
                style: AppText.mono(15, colors.ink),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: colors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recipient and amount appear after Face ID.',
                style: AppText.caption(colors.muted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_rounded, size: 14, color: AppColors.of(context).muted),
        const SizedBox(width: 6),
        Flexible(child: child),
      ],
    );
  }
}

/// Nothing here is ever truncated: this is where money is approved, so
/// the full payee name and every amount are shown, wrapping if needed.
class _RevealedBody extends StatelessWidget {
  const _RevealedBody({required this.state, super.key});

  final ApprovalState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final request = state.request;
    final selected = state.selectedAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ExpiryLabel(request: request),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PartyAvatar(
              id: request.payee.id,
              name: request.payee.name,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      request.payee.name,
                      style: AppText.section(colors.ink),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Masking.iban(request.payee.account),
                    style: AppText.mono(13, colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('You pay', style: AppText.small(colors.muted)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: MoneyText(request.amount, size: 34),
        ),
        const SizedBox(height: 16),
        _InfoBlock(
          rows: [
            _InfoRow(
              label: 'Reference',
              value: Text(
                request.reference,
                style: AppText.mono(14, colors.ink),
              ),
            ),
            if (request.note != null)
              _InfoRow(
                label: 'Note',
                value: Text(
                  request.note!,
                  textAlign: TextAlign.end,
                  style: AppText.bodyMedium(
                    colors.ink,
                  ).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Semantics(
          header: true,
          child: Text('Pay from', style: AppText.label(colors.ink)),
        ),
        const SizedBox(height: 8),
        for (final account in state.accounts) ...[
          _AccountOption(
            account: account,
            request: request,
            selected: account.id == selected?.id,
            enabled: !state.busy,
            onTap: () => context.read<ApprovalBloc>().add(
              ApprovalAccountSelected(account.id),
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedSwitcher(
          duration: Motion.of(context, Motion.fast),
          child: switch (state.notice) {
            _
                when state.selectedCannotCover ||
                    state.notice == ApprovalNotice.insufficientFunds =>
              _Notice.warning(
                'Not enough funds in ${selected?.name ?? 'this account'}. '
                'Pick another account; the request stays open until it '
                'expires.',
                key: const ValueKey('funds'),
              ),
            ApprovalNotice.serviceUnavailable => const _Notice.error(
              'We couldn’t reach the bank. Nothing was sent. Try again.',
              key: ValueKey('service'),
            ),
            _ => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }
}

/// A radio row: the account, what's available, and what's left after
/// paying, each on its own line so no amount is ever cut off.
class _AccountOption extends StatelessWidget {
  const _AccountOption({
    required this.account,
    required this.request,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final Account account;
  final PaymentRequest request;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enough = account.canCover(request.amount);

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fast),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? colors.accent : colors.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.fast),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? colors.accent : const Color(0xFFC3C8D2),
                      width: selected ? 6 : 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(account.name, style: AppText.body(colors.ink)),
                    const SizedBox(height: 6),
                    _AmountLine(
                      label: 'Available',
                      amount: account.availableBalance,
                    ),
                    const SizedBox(height: 2),
                    if (enough)
                      _AmountLine(
                        label: 'After payment',
                        amount: account.availableBalance - request.amount,
                      )
                    else
                      Text(
                        'Not enough funds',
                        style: AppText.small(colors.onDangerContainer),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `label ········ AED 1,234.56`, the amount right-aligned, never cut.
class _AmountLine extends StatelessWidget {
  const _AmountLine({required this.label, required this.amount});

  final String label;
  final Money amount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Text(label, style: AppText.small(colors.muted))),
        const SizedBox(width: 8),
        MoneyText(amount, size: 13, color: colors.ink),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.state, required this.queue});

  final ApprovalState state;
  final ApprovalQueueState queue;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ApprovalBloc>();
    final authenticating = queue.lock == QueueLock.authenticating;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'Reject',
            variant: AppButtonVariant.neutral,
            loading: state.activity == ApprovalActivity.rejecting,
            onPressed: state.canReject
                ? () => bloc.add(const ApprovalRejectRequested())
                : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: state.revealed
              ? AppButton(
                  label: 'Approve',
                  icon: Icons.check_rounded,
                  loading: state.activity == ApprovalActivity.approving,
                  onPressed: state.canApprove
                      ? () => bloc.add(const ApprovalApproveRequested())
                      : null,
                )
              : AppButton(
                  label: queue.unlockNotice == UnlockNotice.failed
                      ? 'Try Face ID again'
                      : 'Review with Face ID',
                  icon: Icons.face_outlined,
                  // No spinner while authenticating: the system prompt on
                  // top is the feedback.
                  onPressed: authenticating || state.busy
                      ? null
                      : () => unawaited(
                          context.read<ApprovalQueueCubit>().unlock(),
                        ),
                ),
        ),
      ],
    );
  }
}

class _ExpiryLabel extends StatelessWidget {
  const _ExpiryLabel({required this.request});

  final PaymentRequest request;

  @override
  Widget build(BuildContext context) {
    final remaining = DateLabels.remaining(request.expiresAt, now: clock.now());
    return Text(
      'Payment request · expires in $remaining',
      style: AppText.caption(
        AppColors.of(context).pending,
      ).copyWith(fontWeight: FontWeight.w800),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.outline),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.semanticValue,
  });

  final String label;
  final Widget value;

  /// Read instead of [value] by assistive technology (e.g. for masks).
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodyMedium(colors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
    if (semanticValue == null) return row;
    return Semantics(
      label: '$label: $semanticValue',
      excludeSemantics: true,
      child: row,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice.error(this.message, {super.key}) : warning = false;

  const _Notice.warning(this.message, {super.key}) : warning = true;

  final String message;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = warning
        ? colors.pendingContainer
        : colors.dangerContainer;
    final foreground = warning
        ? const Color(0xFF6B4500)
        : colors.onDangerContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              warning
                  ? Icons.warning_amber_rounded
                  : Icons.error_outline_rounded,
              size: 20,
              color: foreground,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.bodyMedium(foreground).copyWith(height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
