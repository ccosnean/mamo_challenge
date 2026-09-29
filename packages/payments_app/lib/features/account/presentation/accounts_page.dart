import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_app/core/format/masking.dart';
import 'package:payments_app/core/format/money_format.dart';
import 'package:payments_app/core/money/currency.dart';
import 'package:payments_app/core/money/money.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/money_text.dart';
import 'package:payments_app/core/ui/widgets/section_card.dart';
import 'package:payments_app/features/account/domain/domain.dart';
import 'package:payments_app/features/account/presentation/accounts_cubit.dart';

/// The company's accounts and their available balances.
class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  /// Below this, an account is flagged so the user isn't surprised when a
  /// payment from it is refused.
  static const Money lowBalance = Money.minor(50000, Currency.aed);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final state = context.watch<AccountsCubit>().state;
    final hidden = context.watch<BalanceVisibilityCubit>().state;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
          child: Semantics(
            header: true,
            child: Text('Accounts', style: AppText.title(colors.ink)),
          ),
        ),
        if (!state.loaded)
          const Center(child: CircularProgressIndicator())
        else
          SectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < state.accounts.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: colors.divider),
                  _AccountRow(
                    account: state.accounts[i],
                    tile: _tiles[i % _tiles.length],
                    hidden: hidden,
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'All accounts are in AED, so the total in the top bar is an '
            'exact sum.',
            style: AppText.caption(colors.muted),
          ),
        ),
      ],
    );
  }

  static const List<Color> _tiles = [
    Color(0xFF0F1115),
    Color(0xFF2F5BEA),
    Color(0xFF0B6B3A),
    Color(0xFF6B3FB0),
  ];
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.tile,
    required this.hidden,
  });

  final Account account;
  final Color tile;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final low = account.availableBalance < AccountsPage.lowBalance;
    final balance = account.availableBalance;

    final spokenBalance = hidden
        ? 'balance hidden'
        : '${balance.currency.code} ${MoneyFormat.amount(balance)}';

    return Semantics(
      label:
          '${account.name}, account ending ${account.iban.lastFour}, '
          '$spokenBalance${low ? ', low balance' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tile,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(colors.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Masking.iban(account.iban),
                    style: AppText.mono(12, colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                MoneyText(balance, masked: hidden),
                if (low) ...[
                  const SizedBox(height: 2),
                  Text('Low balance', style: AppText.small(colors.pending)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
