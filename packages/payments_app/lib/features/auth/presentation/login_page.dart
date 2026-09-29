import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';
import 'package:payments_app/core/ui/widgets/app_button.dart';
import 'package:payments_app/core/ui/widgets/party_avatar.dart';
import 'package:payments_app/core/ui/widgets/section_card.dart';
import 'package:payments_app/features/auth/presentation/demo_account.dart';
import 'package:payments_app/features/auth/presentation/login_cubit.dart';

/// Sign-in. With a [demoAccount] (showcase), it describes the demo user and
/// signs in with one tap; otherwise it asks for a username and password.
class LoginPage extends StatefulWidget {
  const LoginPage({this.demoAccount, super.key});

  final DemoAccount? demoAccount;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _signIn() {
    final demo = widget.demoAccount;
    final cubit = context.read<LoginCubit>();
    if (demo != null) {
      unawaited(
        cubit.signIn(username: demo.username, password: demo.password),
      );
    } else {
      unawaited(
        cubit.signIn(username: _username.text, password: _password.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final demo = widget.demoAccount;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          'Welcome back',
                          style: AppText.title(colors.ink),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to review and approve payment requests.',
                        style: AppText.bodyMedium(
                          colors.muted,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),
                      if (demo != null)
                        _DemoUserCard(account: demo)
                      else
                        _CredentialsForm(
                          username: _username,
                          password: _password,
                          onSubmit: _signIn,
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: _SignInAction(onPressed: _signIn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoUserCard extends StatelessWidget {
  const _DemoUserCard({required this.account});

  final DemoAccount account;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final role = account.role;

    return SectionCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.accentContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text(
                'Demo account',
                style: AppText.small(colors.onAccentContainer),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              PartyAvatar(id: account.username, name: account.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: AppText.label(colors.ink).copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [?role, account.companyName].join(' · '),
                      style: AppText.caption(colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.fill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _CredentialRow(label: 'Username', value: account.username),
                  Divider(height: 1, color: colors.outline),
                  const _CredentialRow(
                    label: 'Password',
                    value: '••••••••••',
                    semanticValue: 'hidden',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Credentials are filled in for the demo.',
            style: AppText.caption(colors.muted),
          ),
        ],
      ),
    );
  }
}

class _CredentialsForm extends StatelessWidget {
  const _CredentialsForm({
    required this.username,
    required this.password,
    required this.onSubmit,
  });

  final TextEditingController username;
  final TextEditingController password;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        children: [
          TextField(
            controller: username,
            autofillHints: const [AutofillHints.username],
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            autofillHints: const [AutofillHints.password],
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ],
      ),
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    this.semanticValue,
  });

  final String label;
  final String value;
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Semantics(
      label: '$label: ${semanticValue ?? value}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            Text(label, style: AppText.bodyMedium(colors.muted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.mono(14, colors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInAction extends StatelessWidget {
  const _SignInAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final status = context.watch<LoginCubit>().state;
    final message = switch (status) {
      LoginStatus.invalidCredentials =>
        'Those details weren’t recognised. Check the username and password.',
      LoginStatus.failed => 'We couldn’t sign you in. Try again.',
      _ => null,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMedium(colors.danger),
            ),
          ),
          const SizedBox(height: 12),
        ],
        AppButton(
          label: 'Sign in',
          icon: Icons.login_rounded,
          loading: status == LoginStatus.submitting,
          onPressed: onPressed,
        ),
      ],
    );
  }
}
