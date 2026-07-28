import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';
import '../../../app/theme/wb_tokens.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/services/analytics/analytics_service.dart';
import '../data/auth_repository.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email: _email.text.trim(),
            password: _password.text,
          );
      await ref.read(analyticsProvider).signUpCompleted(method: 'email');
      if (!mounted) return;
      if (ref.read(authRepositoryProvider).currentSession != null) {
        context.goNamed(Routes.onboarding);
      } else {
        // Email confirmation is enabled on the project: no session until the
        // link is clicked. The deep link brings the user back signed in.
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Check your email to confirm your account, then come back and sign in.')));
        context.goNamed(Routes.signIn);
      }
    } on AppException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(WbSpacing.lg),
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: WbSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Password', helperText: 'At least 8 characters'),
                validator: (v) => (v == null || v.length < 8)
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: WbSpacing.md),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: WbSpacing.md),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: WbSpacing.lg),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
