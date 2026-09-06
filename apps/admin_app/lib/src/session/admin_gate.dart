import 'package:admin_app/src/session/admin_session_state.dart';
import 'package:admin_app/src/session/admin_session_view_model.dart';
import 'package:commerce_admin_shared/commerce_admin_shared.dart';
import 'package:dust_dart/fp.dart';
import 'package:flutter/material.dart';

/// Switches between sign-in and the authenticated admin shell.
final class AdminGate extends StatelessWidget {
  /// Creates the gate.
  const AdminGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watchAdminSessionViewModel().value;
    return switch (state.user) {
      Some(value: final user) => _AdminHome(user: user, state: state),
      None() when state.status == AdminSessionStatus.initial || state.isBusy =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      None() => _AdminSignIn(state: state),
    };
  }
}

final class _AdminSignIn extends StatefulWidget {
  const _AdminSignIn({required this.state});

  final AdminSessionState state;

  @override
  State<_AdminSignIn> createState() => _AdminSignInState();
}

final class _AdminSignInState extends State<_AdminSignIn> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Morrow',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your store',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      autofillHints: const [AutofillHints.username],
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      autofillHints: const [AutofillHints.password],
                      obscureText: true,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (widget.state.failure case Some(value: final message))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: widget.state.isBusy ? null : _submit,
                      child: const Text('Sign in'),
                    ),
                    const SizedBox(height: 24),
                    const Center(child: Text('Powered by dust')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  void _submit() {
    FocusScope.of(context).unfocus();
    context.readAdminSessionViewModel().signIn(_email.text, _password.text);
  }
}

final class _AdminHome extends StatelessWidget {
  const _AdminHome({required this.user, required this.state});

  final AdminSessionState state;
  final AdminUser user;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Morrow'),
          actions: [
            TextButton(
              onPressed: state.isBusy
                  ? null
                  : context.readAdminSessionViewModel().signOut,
              child: const Text('Sign out'),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 16),
              Text('Signed in as ${user.email}'),
              if (state.failure case Some(value: final message)) ...[
                const SizedBox(height: 12),
                Text(message),
              ],
            ],
          ),
        ),
      );
}
