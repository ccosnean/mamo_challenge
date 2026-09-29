import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:payments_app/app/routes.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/format/money_format.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/party_avatar.dart';
import 'package:payments_app/core/ui/widgets/pressable.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/widgets/payment_status_view.dart';

enum PaymentRowDate {
  /// `Today, 14:32` / `21 Sep`: for mixed-day lists.
  short,

  /// `14:32`: when the list is already grouped by day.
  time,
}

/// One decided payment: who, when, how much, and its status. Opens details.
///
/// The amount keeps its full width; the name and note give way.
class PaymentRow extends StatelessWidget {
  const PaymentRow(
    this.payment, {
    this.date = PaymentRowDate.short,
    this.showStatus = true,
    super.key,
  });

  final Payment payment;
  final PaymentRowDate date;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final when = switch (date) {
      PaymentRowDate.short => DateLabels.short(
        payment.decidedAt,
        now: clock.now(),
      ),
      PaymentRowDate.time => DateLabels.time(payment.decidedAt),
    };
    final meta = [when, ?payment.note].join(' · ');
    final approved = payment.status.isApproved;

    return Pressable(
      onTap: () => context.push(AppRoutes.paymentDetails(payment.id)),
      semanticLabel:
          '${payment.payee.name}, ${payment.amount.currency.code} '
          '${MoneyFormat.amount(payment.amount)}, ${payment.status.label}, '
          '$meta',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            PartyAvatar(id: payment.payee.id, name: payment.payee.name),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.payee.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(colors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption(colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(
                  payment.amount,
                  color: approved ? colors.ink : colors.muted,
                  strikethrough: !approved,
                ),
                if (showStatus) ...[
                  const SizedBox(height: 2),
                  StatusText(payment.status),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
