import 'package:flutter/material.dart';
import 'package:payments_app/core/format/money_format.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';

/// An amount in the money typeface: the currency code smaller and muted,
/// then the number. Never wraps, so it keeps its width in a row and the
/// label next to it gives way instead.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.money, {
    this.size = 15,
    this.color,
    this.strikethrough = false,
    this.masked = false,
    super.key,
  });

  final Money money;
  final double size;
  final Color? color;

  /// For rejected payments: the amount that did not move.
  final bool strikethrough;

  /// Shows a fixed-width mask instead of the number.
  final bool masked;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final valueStyle = AppText.mono(size, color ?? colors.ink).copyWith(
      decoration: strikethrough ? TextDecoration.lineThrough : null,
      letterSpacing: size >= 24 ? -1 : null,
    );
    final codeStyle = AppText.mono(size * 0.62 + 3, colors.muted).copyWith(
      letterSpacing: 0,
    );
    final value = masked ? MoneyFormat.masked : MoneyFormat.amount(money);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${money.currency.code} ', style: codeStyle),
          TextSpan(text: value, style: valueStyle),
        ],
      ),
      maxLines: 1,
      softWrap: false,
      textAlign: TextAlign.end,
      semanticsLabel: masked
          ? 'Amount hidden'
          : '${money.currency.code} $value${strikethrough ? ', not paid' : ''}',
    );
  }
}

/// A [MoneyText] that counts to its new value when the amount changes, e.g.
/// a balance after an approval.
class AnimatedMoneyText extends StatelessWidget {
  const AnimatedMoneyText(this.money, {this.size = 15, super.key});

  final Money money;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: money.minorUnits.toDouble()),
      duration: Motion.of(context, Motion.slow),
      curve: Motion.standard,
      builder: (context, value, _) => MoneyText(
        Money.minor(value.round(), money.currency),
        size: size,
      ),
    );
  }
}
