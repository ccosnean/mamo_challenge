import 'package:flutter/material.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/features/payments/domain/domain.dart';

/// How a [PaymentStatus] reads and looks. Every status has a text label;
/// colour is never the only signal.
extension PaymentStatusView on PaymentStatus {
  /// What the user did or what happened: `Approved`, `Rejected`, …
  String get label => switch (this) {
    PaymentStatus.completed => 'Approved',
    PaymentStatus.processing => 'Processing',
    PaymentStatus.rejected => 'Rejected',
    PaymentStatus.failed => 'Failed',
  };

  /// The settlement state, for details: `Completed`, `Not paid`, …
  String get settlement => switch (this) {
    PaymentStatus.completed => 'Completed',
    PaymentStatus.processing => 'In progress',
    PaymentStatus.rejected => 'Not paid',
    PaymentStatus.failed => 'Failed',
  };

  IconData get icon => switch (this) {
    PaymentStatus.completed => Icons.check_rounded,
    PaymentStatus.processing => Icons.schedule_rounded,
    PaymentStatus.rejected => Icons.close_rounded,
    PaymentStatus.failed => Icons.error_outline_rounded,
  };

  (Color foreground, Color background) colors(AppColors colors) =>
      switch (this) {
        PaymentStatus.completed => (colors.success, colors.successContainer),
        PaymentStatus.processing => (
          colors.onAccentContainer,
          colors.accentContainer,
        ),
        PaymentStatus.rejected || PaymentStatus.failed => (
          colors.danger,
          colors.dangerContainer,
        ),
      };
}

/// Small coloured status text under an amount in a row.
class StatusText extends StatelessWidget {
  const StatusText(this.status, {super.key});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, _) = status.colors(AppColors.of(context));
    return Text(status.label, style: AppText.small(foreground));
  }
}

/// Status pill with an icon, for details.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = status.colors(AppColors.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: foreground),
            const SizedBox(width: 6),
            Text(
              status.label,
              style: AppText.caption(foreground).copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
