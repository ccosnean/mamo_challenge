import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:payments_app/app/routes.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/format/masking.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/app_button.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/party_avatar.dart';
import 'package:payments_app/core/ui/widgets/section_card.dart';
import 'package:payments_app/features/account/presentation/accounts_cubit.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';
import 'package:payments_app/features/payments/presentation/widgets/payment_status_view.dart';

/// Full details of a decided payment.
///
/// Looks the payment up in the decided history only, so a pending request
/// (or a stale link) can never open here; it gets a clear "not available"
/// state instead.
class PaymentDetailsPage extends StatelessWidget {
  const PaymentDetailsPage({required this.paymentId, super.key});

  final PaymentId paymentId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final history = context.watch<PaymentHistoryCubit>().state;
    final payment = history.byId(paymentId);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  _BackButton(onPressed: () => _back(context)),
                  const SizedBox(width: 8),
                  Semantics(
                    header: true,
                    child: Text(
                      'Payment details',
                      style: AppText.label(colors.ink).copyWith(fontSize: 17),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !history.loaded
                  ? const Center(child: CircularProgressIndicator())
                  : payment == null
                  ? _NotAvailable(onBack: () => _back(context))
                  : _Details(payment: payment),
            ),
          ],
        ),
      ),
    );
  }

  /// Back to wherever details was opened from; home if opened directly.
  static void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'Back',
      excludeSemantics: true,
      child: Material(
        color: colors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Icon(Icons.arrow_back_rounded, size: 22, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final paidFrom = context.select<AccountsCubit, String?>((cubit) {
      final account = cubit.state.byId(payment.debtorAccountId);
      return account == null
          ? null
          : '${account.name} · ${Masking.iban(account.iban)}';
    });
    final approved = payment.status.isApproved;

    final rows = <(String, String, bool)>[
      ('Status', payment.status.settlement, false),
      ('Date', DateLabels.full(payment.decidedAt), false),
      ('Reference', payment.reference, true),
      if (payment.note != null) ('Note', payment.note!, false),
      ('Paid to', Masking.iban(payment.payee.account), true),
      ('Requested', DateLabels.full(payment.requestedAt), false),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
      children: [
        Column(
          children: [
            PartyAvatar(
              id: payment.payee.id,
              name: payment.payee.name,
              size: 64,
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: MoneyText(
                payment.amount,
                size: 36,
                strikethrough: !approved,
                color: approved ? colors.ink : colors.muted,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'to ${payment.payee.name}',
              textAlign: TextAlign.center,
              style: AppText.body(colors.muted).copyWith(fontSize: 16),
            ),
            const SizedBox(height: 10),
            StatusPill(payment.status),
          ],
        ),
        const SizedBox(height: 20),
        SectionCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.divider),
                _DetailRow(
                  label: rows[i].$1,
                  value: rows[i].$2,
                  mono: rows[i].$3,
                ),
              ],
            ],
          ),
        ),
        if (paidFrom != null) ...[
          const SizedBox(height: 16),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Paid from', style: AppText.caption(colors.muted)),
                      const SizedBox(height: 2),
                      Text(
                        paidFrom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label(colors.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.mono,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.bodyMedium(colors.muted)),
          const SizedBox(width: 16),
          Expanded(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: mono
                  ? AppText.mono(15, colors.ink)
                  : AppText.label(colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotAvailable extends StatelessWidget {
  const _NotAvailable({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: colors.muted),
            const SizedBox(height: 12),
            Text(
              'This payment isn’t available',
              textAlign: TextAlign.center,
              style: AppText.section(colors.ink),
            ),
            const SizedBox(height: 6),
            Text(
              'Details exist only for payments you’ve approved or rejected.',
              textAlign: TextAlign.center,
              style: AppText.caption(colors.muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 200,
              child: AppButton(
                label: 'Go back',
                variant: AppButtonVariant.neutral,
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
