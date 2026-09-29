import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:payments_app/app/routes.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/section_card.dart';
import 'package:payments_app/features/home/presentation/home_cubit.dart';
import 'package:payments_app/features/payments/presentation/widgets/payment_row.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          _MonthSummary(state: state),
          const SizedBox(height: 16),
          _Recent(state: state),
        ],
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spent in ${DateLabels.month(state.month)}',
                  style: AppText.bodyMedium(colors.muted),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accentContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(
                    'This month',
                    style: AppText.small(colors.onAccentContainer),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedMoneyText(state.summary.total, size: 34),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Payments',
                  value: '${state.summary.count}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Rejected',
                  value: '${state.rejectedThisMonth}',
                  suffix: 'not counted',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.suffix});

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: '$label: $value${suffix == null ? '' : ', $suffix'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: colors.fill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.small(colors.muted)),
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: AppText.mono(20, colors.ink)),
                if (suffix != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      suffix!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.small(colors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Recent extends StatelessWidget {
  const _Recent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Recent', style: AppText.section(colors.ink)),
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.payments),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accent,
                  textStyle: AppText.bodyMedium(colors.accent),
                ),
                child: const Text('See all'),
              ),
            ],
          ),
          if (!state.loaded)
            const _RowsPlaceholder()
          else if (state.recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No approved payments yet.',
                style: AppText.caption(colors.muted),
              ),
            )
          else
            for (final payment in state.recent)
              PaymentRow(payment, showStatus: false, key: ValueKey(payment.id)),
        ],
      ),
    );
  }
}

class _RowsPlaceholder extends StatelessWidget {
  const _RowsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget bar(double width) => Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Semantics(
      label: 'Loading payments',
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(radius: 22, backgroundColor: colors.fill),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [bar(140), const SizedBox(height: 8), bar(90)],
                    ),
                  ),
                  bar(70),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
