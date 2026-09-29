import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/format/masking.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/pressable.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

/// A request waiting on the user. Masked like the approval sheet, so the
/// list never shows what the sheet hides. Tapping it opens the sheet.
class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    required this.request,
    required this.onTap,
    super.key,
  });

  final PaymentRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final remaining = DateLabels.remaining(request.expiresAt, now: clock.now());

    return Pressable(
      onTap: onTap,
      semanticLabel:
          'Payment request ${request.reference}. Recipient and amount '
          'hidden. Expires in $remaining. Review',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.pendingBorder, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colors.pendingContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 22,
                    color: colors.pending,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Masking.name(request.payee.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(colors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.reference,
                        style: AppText.mono(13, colors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                MoneyText(request.amount, masked: true),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: colors.muted,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ExpiryBar(request: request),
          ],
        ),
      ),
    );
  }
}

/// Time left to decide, as a draining bar. Refreshes every 30 seconds.
class _ExpiryBar extends StatefulWidget {
  const _ExpiryBar({required this.request});

  final PaymentRequest request;

  @override
  State<_ExpiryBar> createState() => _ExpiryBarState();
}

class _ExpiryBarState extends State<_ExpiryBar> {
  late final Timer _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final request = widget.request;
    final now = clock.now();
    final total = request.expiresAt.difference(request.createdAt).inSeconds;
    final left = request.expiresAt.difference(now).inSeconds;
    final fraction = total <= 0 ? 0.0 : (left / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: colors.fill),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: fraction,
                  child: ColoredBox(color: colors.pendingBar),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Expires in ${DateLabels.remaining(request.expiresAt, now: now)}',
          style: AppText.small(colors.pending),
        ),
      ],
    );
  }
}
