import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:payments_app/app/shell/top_bar.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/features/payments/presentation/payments_cubits.dart';

/// Top bar, the current tab, and the tab bar.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const TopBar(),
            Expanded(child: shell),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          // Tapping the current tab again returns it to its first screen.
          onDestinationSelected: (index) => shell.goBranch(
            index,
            initialLocation: index == shell.currentIndex,
          ),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: _PendingBadge(child: Icon(Icons.swap_horiz_rounded)),
              label: 'Payments',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Accounts',
            ),
          ],
        ),
      ),
    );
  }
}

/// Pending-request count on the Payments tab. Pops when it changes.
class _PendingBadge extends StatelessWidget {
  const _PendingBadge({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final count = context.select<PendingRequestsCubit, int>(
      (cubit) => cubit.state.length,
    );

    return Semantics(
      value: count == 0 ? null : '$count waiting',
      child: Badge(
        isLabelVisible: count > 0,
        offset: const Offset(8, -6),
        label: TweenAnimationBuilder<double>(
          key: ValueKey(count),
          tween: Tween(begin: 0.4, end: 1),
          duration: Motion.of(context, Motion.medium),
          curve: Curves.elasticOut,
          builder: (context, scale, label) =>
              Transform.scale(scale: scale, child: label),
          child: Text('$count'),
        ),
        child: child,
      ),
    );
  }
}
