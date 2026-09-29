import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_app/core/format/money_format.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/app_button.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/party_avatar.dart';
import 'package:payments_app/core/ui/widgets/pressable.dart';
import 'package:payments_app/features/account/presentation/accounts_cubit.dart';
import 'package:payments_app/features/auth/domain/domain.dart';
import 'package:payments_app/features/auth/presentation/session_cubit.dart';

/// The user and their company on the left, the total balance across
/// accounts on the right. Tapping the balance hides it; tapping the user
/// opens account options (sign out).
class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = context.watch<SessionCubit>().state;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Pressable(
              onTap: user == null ? null : () => _showAccountSheet(context),
              semanticLabel: user == null
                  ? null
                  : '${user.name}, ${user.company.name}. Account options',
              child: Row(
                children: [
                  if (user != null)
                    PartyAvatar(id: user.id, name: user.name, size: 40)
                  else
                    CircleAvatar(radius: 20, backgroundColor: colors.outline),
                  const SizedBox(width: 12),
                  Expanded(child: _Identity(user: user)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          const _TotalBalance(),
        ],
      ),
    );
  }
}

Future<void> _showAccountSheet(BuildContext context) async {
  final session = context.read<SessionCubit>();
  // Captured once: the sheet keeps rendering while it closes, after the
  // session may already be gone.
  final user = session.state;
  if (user == null) return;
  final signOut = await showModalBottomSheet<bool>(
    context: context,
    builder: (_) => _AccountSheet(user: user),
  );
  if (signOut ?? false) await session.signOut();
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PartyAvatar(id: user.id, name: user.name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppText.label(colors.ink).copyWith(fontSize: 17),
                      ),
                      Text(
                        user.company.name,
                        style: AppText.caption(colors.muted),
                      ),
                      Text(
                        user.username,
                        style: AppText.mono(12, colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Sign out',
              icon: Icons.logout_rounded,
              variant: AppButtonVariant.danger,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final user = this.user;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          user.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.label(colors.ink).copyWith(fontSize: 16),
        ),
        Text(
          user.company.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption(colors.muted),
        ),
      ],
    );
  }
}

class _TotalBalance extends StatelessWidget {
  const _TotalBalance();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accounts = context.watch<AccountsCubit>().state;
    final hidden = context.watch<BalanceVisibilityCubit>().state;
    final total = accounts.total;

    return Semantics(
      button: true,
      label: hidden
          ? 'Total balance hidden. Show balance'
          : 'Total balance ${total.currency.code} '
                '${MoneyFormat.amount(total)}. Hide balance',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: context.read<BalanceVisibilityCubit>().toggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Total balance', style: AppText.small(colors.muted)),
                  const SizedBox(width: 4),
                  Icon(
                    hidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 14,
                    color: colors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AnimatedSwitcher(
                duration: Motion.of(context, Motion.fast),
                child: !accounts.loaded
                    ? const SizedBox(height: 22)
                    : hidden
                    ? MoneyText(
                        total,
                        size: 18,
                        masked: true,
                        key: const ValueKey('hidden'),
                      )
                    : AnimatedMoneyText(
                        total,
                        size: 18,
                        key: const ValueKey('shown'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
