import 'package:flutter/material.dart';
import 'package:mock_bank/mock_bank.dart';
import 'package:showcase/src/ui/panel.dart';

/// Controls for the mock bank: what a server team (or the outside world)
/// would do to the backend, shown next to the device.
class BankPanel extends StatelessWidget {
  const BankPanel({required this.server, super.key});

  final MockBankServer server;

  static const int _topUpFils = 500000; // AED 5,000.00

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BankSnapshot>(
      stream: server.watch(),
      initialData: server.snapshot,
      builder: (context, snapshot) {
        final bank = snapshot.requireData;
        return Panel(
          icon: Icons.account_balance_rounded,
          title: 'Bank',
          subtitle: 'Mock server behind the app’s HTTP client',
          trailing: _Status(offline: bank.offline),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PanelButton(
                label: 'Send payment request',
                icon: Icons.call_received_rounded,
                primary: true,
                onPressed: server.sendPaymentRequest,
              ),
              const SizedBox(height: 6),
              const Text(
                'The app polls every 5 s, so it appears within a few '
                'seconds.',
                style: TextStyle(
                  color: Workbench.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Accounts (server view)'),
              for (final account in bank.accounts)
                StatRow(
                  label: account.name,
                  value: 'AED ${_amount(account.balance)}',
                ),
              const SizedBox(height: 8),
              PanelButton(
                label: 'Top up lowest +AED 5,000',
                icon: Icons.add_card_rounded,
                onPressed: () => server.topUp(_topUpFils),
              ),
              const SizedBox(height: 6),
              const Text(
                'Balances in the app refresh on the same 5 s poll.',
                style: TextStyle(color: Workbench.muted, fontSize: 12),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('Network'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Online',
                  style: TextStyle(color: Workbench.text, fontSize: 13),
                ),
                subtitle: const Text(
                  'Off: every call fails like a dead connection',
                  style: TextStyle(color: Workbench.muted, fontSize: 12),
                ),
                value: !bank.offline,
                onChanged: (online) => server.offline = !online,
              ),
              Row(
                children: [
                  const Text(
                    'Latency',
                    style: TextStyle(color: Workbench.muted, fontSize: 13),
                  ),
                  Expanded(
                    child: Slider(
                      value: bank.latency.inMilliseconds.toDouble(),
                      max: 3000,
                      divisions: 30,
                      onChanged: (value) => server.latency = Duration(
                        milliseconds: value.round(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '${bank.latency.inMilliseconds} ms',
                      textAlign: TextAlign.end,
                      style: Workbench.monoStyle(12, Workbench.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _SectionLabel('Sessions'),
              StatRow(label: 'Active tokens', value: '${bank.activeSessions}'),
              StatRow(label: 'Pending requests', value: '${bank.pendingCount}'),
              StatRow(
                label: 'Payments on record',
                value: '${bank.paymentsCount}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  PanelButton(
                    label: 'Expire session',
                    icon: Icons.timer_off_outlined,
                    onPressed: server.revokeAllTokens,
                  ),
                  PanelButton(
                    label: 'Reset bank',
                    icon: Icons.restart_alt_rounded,
                    destructive: true,
                    onPressed: server.reset,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _amount(int fils) {
    final whole = (fils ~/ 100).toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$whole.${(fils % 100).toString().padLeft(2, '0')}';
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final color = offline ? Workbench.bad : Workbench.good;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          offline ? 'Offline' : 'Online',
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Workbench.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
