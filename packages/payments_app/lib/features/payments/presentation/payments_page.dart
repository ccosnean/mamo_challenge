import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_app/core/format/date_format.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/appear.dart';
import 'package:payments_app/core/ui/widgets/section_card.dart';
import 'package:payments_app/features/approval/presentation/approval_coordinator.dart';
import 'package:payments_app/features/payments/domain/domain.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';
import 'package:payments_app/features/payments/presentation/widgets/payment_row.dart';
import 'package:payments_app/features/payments/presentation/widgets/pending_request_card.dart';

/// Requests waiting on the user on top, then every decided payment, most
/// recent first, grouped by day.
class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  /// Ids already on screen. Anything new animates in; the first load doesn't.
  Set<Object>? _seen;

  bool _isNew(Object id) {
    final seen = _seen;
    if (seen == null) return false;
    return seen.add(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final history = context.watch<PaymentHistoryCubit>().state;
    final pending = context.watch<PendingRequestsCubit>().state;

    final groups = _groupByDay(history.payments);
    final newIds = <Object>{
      for (final payment in history.payments)
        if (_isNew(payment.id)) payment.id,
      for (final request in pending)
        if (_isNew(request.id)) request.id,
    };
    if (history.loaded) {
      _seen ??= {
        for (final payment in history.payments) payment.id,
        for (final request in pending) request.id,
      };
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              header: true,
              child: Text('Payments', style: AppText.title(colors.ink)),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.standard,
              alignment: Alignment.topCenter,
              child: pending.isEmpty
                  ? const SizedBox(width: double.infinity)
                  : _PendingSection(pending: pending, newIds: newIds),
            ),
          ),
        ),
        if (!history.loaded)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (groups.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Text(
                'No payments yet.',
                style: AppText.caption(colors.muted),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList.builder(
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final (day, payments) = groups[index];
                return _DayGroup(
                  key: ValueKey(day),
                  day: day,
                  payments: payments,
                  newIds: newIds,
                );
              },
            ),
          ),
      ],
    );
  }

  /// Consecutive payments on the same local day, keeping the list order.
  static List<(String, List<Payment>)> _groupByDay(List<Payment> payments) {
    final now = clock.now();
    final groups = <(String, List<Payment>)>[];
    for (final payment in payments) {
      final day = DateLabels.day(payment.decidedAt, now: now);
      if (groups.isEmpty || groups.last.$1 != day) {
        groups.add((day, [payment]));
      } else {
        groups.last.$2.add(payment);
      }
    }
    return groups;
  }
}

class _PendingSection extends StatelessWidget {
  const _PendingSection({required this.pending, required this.newIds});

  final List<PaymentRequest> pending;
  final Set<Object> newIds;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Waiting for you',
                    style: AppText.label(colors.ink),
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.pendingContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      '${pending.length}',
                      style: AppText.small(colors.pending),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final request in pending)
            Appear(
              key: ValueKey(request.id),
              animate: newIds.contains(request.id),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: PendingRequestCard(
                  request: request,
                  onTap: () => ApprovalLauncher.of(context).review(request),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.day,
    required this.payments,
    required this.newIds,
    super.key,
  });

  final String day;
  final List<Payment> payments;
  final Set<Object> newIds;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Semantics(
              header: true,
              child: Text(
                day,
                style: AppText.caption(
                  colors.muted,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            radius: 20,
            child: Column(
              children: [
                for (final payment in payments)
                  Appear(
                    key: ValueKey(payment.id),
                    animate: newIds.contains(payment.id),
                    child: PaymentRow(payment, date: PaymentRowDate.time),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
