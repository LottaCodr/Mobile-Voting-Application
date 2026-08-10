import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../data/app_services.dart';
import '../../data/auth_gateway.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

enum _AuthView { welcome, signIn, signUp }

class SignedOutScreen extends ConsumerStatefulWidget {
  const SignedOutScreen({super.key});

  @override
  ConsumerState<SignedOutScreen> createState() => _SignedOutScreenState();
}

class _SignedOutScreenState extends ConsumerState<SignedOutScreen> {
  _AuthView _view = _AuthView.welcome;

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _AuthView.welcome => _WelcomePanel(
        onSignIn: () => setState(() => _view = _AuthView.signIn),
        onSignUp: () => setState(() => _view = _AuthView.signUp),
      ),
      _AuthView.signIn => _AuthPanel(
        mode: _AuthView.signIn,
        onBack: () => setState(() => _view = _AuthView.welcome),
        onSwitch: () => setState(() => _view = _AuthView.signUp),
      ),
      _AuthView.signUp => _AuthPanel(
        mode: _AuthView.signUp,
        onBack: () => setState(() => _view = _AuthView.welcome),
        onSwitch: () => setState(() => _view = _AuthView.signIn),
      ),
    };
  }
}

class _WelcomePanel extends ConsumerWidget {
  const _WelcomePanel({required this.onSignIn, required this.onSignUp});

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appServicesProvider).mode;
    final isDemo = mode == AppDataMode.demo;
    return Scaffold(
      body: PageFrame(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 14),
                  const AppLogo(),
                  const SizedBox(height: 56),
                  _SecurityChip(isDemo: isDemo),
                  const SizedBox(height: 18),
                  Text(
                    'Your voice, ready when you are.',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                      height: 1.08,
                      letterSpacing: -1.25,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isDemo
                        ? 'Explore an accessible, fictional multi-contest ballot before connecting your own Supabase project.'
                        : 'Review eligible ballots, complete secure verification, and follow authority-published results in one calm place.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted, height: 1.55),
                  ),
                  const SizedBox(height: 32),
                  const _PromiseRow(
                    icon: Icons.fact_check_outlined,
                    title: 'Review every contest',
                    description: 'Your ballot stays editable until the explicit confirmation step.',
                  ),
                  const SizedBox(height: 18),
                  const _PromiseRow(
                    icon: Icons.verified_user_outlined,
                    title: 'Eligibility-aware',
                    description: 'Only authority-assigned ballots can be submitted.',
                  ),
                  const SizedBox(height: 18),
                  const _PromiseRow(
                    icon: Icons.visibility_off_outlined,
                    title: 'Privacy by design',
                    description: 'Submission status and receipts never reveal a candidate choice.',
                  ),
                  const SizedBox(height: 38),
                  if (isDemo) ...<Widget>[
                    FilledButton.icon(
                      key: const Key('exploreDemoButton'),
                      onPressed: () => ref.read(sessionProvider.notifier).enterDemo(),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Explore demo ballot'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Nothing in demo mode is an official vote.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ] else ...<Widget>[
                    FilledButton(
                      key: const Key('signInButton'),
                      onPressed: onSignIn,
                      child: const Text('Sign in securely'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      key: const Key('createAccountButton'),
                      onPressed: onSignUp,
                      child: const Text('Create a voter account'),
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityChip extends StatelessWidget {
  const _SecurityChip({required this.isDemo});

  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final color = isDemo ? AppColors.gold : AppColors.teal;
    final background = isDemo ? AppColors.goldPale : AppColors.tealPale;
    return Semantics(
      label: isDemo ? 'CivicVote product preview' : 'CivicVote secure voter portal',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              isDemo ? Icons.science_outlined : Icons.lock_outline_rounded,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 7),
            Text(
              isDemo ? 'PRODUCT PREVIEW' : 'SECURE VOTER PORTAL',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromiseRow extends StatelessWidget {
  const _PromiseRow({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.bluePale,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.blueDark, size: 21),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 3),
              Text(description, style: const TextStyle(color: AppColors.inkMuted, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthPanel extends ConsumerStatefulWidget {
  const _AuthPanel({required this.mode, required this.onBack, required this.onSwitch});

  final _AuthView mode;
  final VoidCallback onBack;
  final VoidCallback onSwitch;

  @override
  ConsumerState<_AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends ConsumerState<_AuthPanel> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isBusy = false;

  bool get _isSignUp => widget.mode == _AuthView.signUp;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isBusy = true);
    try {
      if (_isSignUp) {
        final result = await ref
            .read(sessionProvider.notifier)
            .signUp(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        if (mounted && result.requiresEmailConfirmation) {
          _message('Check your email to confirm the account, then sign in.');
          widget.onSwitch();
        }
      } else {
        await ref
            .read(sessionProvider.notifier)
            .signIn(email: _emailController.text.trim(), password: _passwordController.text);
      }
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } catch (_) {
      if (mounted) _message('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_isEmail(email)) {
      _message('Enter your email address first, then try again.');
      return;
    }
    setState(() => _isBusy = true);
    try {
      await ref.read(sessionProvider.notifier).resetPassword(email);
      if (mounted) _message('If an account exists for that address, a reset email is on its way.');
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create your voter account' : 'Welcome back';
    final subtitle = _isSignUp
        ? 'Use details that match your eligibility record. Verification happens separately.'
        : 'Sign in to view your assigned elections and secure ballot status.';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: _isBusy ? null : widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const AppLogo(compact: true),
      ),
      body: PageFrame(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(subtitle, style: const TextStyle(color: AppColors.inkMuted, height: 1.5)),
                    const SizedBox(height: 30),
                    if (_isSignUp) ...<Widget>[
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const <String>[AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) =>
                            (value ?? '').trim().length < 2 ? 'Enter your full name.' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email address',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                      validator: (value) =>
                          _isEmail(value?.trim() ?? '') ? null : 'Enter a valid email address.',
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: _isSignUp ? TextInputAction.next : TextInputAction.done,
                      autofillHints: <String>[
                        _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) {
                        if (!_isSignUp) unawaited(_submit());
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) =>
                          (value ?? '').length < 8 ? 'Use at least 8 characters.' : null,
                    ),
                    if (_isSignUp) ...<Widget>[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const <String>[AutofillHints.newPassword],
                        onFieldSubmitted: (_) => unawaited(_submit()),
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: const Icon(Icons.lock_reset_outlined),
                          suffixIcon: IconButton(
                            tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                            onPressed: () =>
                                setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value != _passwordController.text ? 'Passwords do not match.' : null,
                      ),
                    ],
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isBusy ? null : () => unawaited(_resetPassword()),
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isBusy ? null : () => unawaited(_submit()),
                      child: _isBusy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(_isSignUp ? 'Create account' : 'Sign in securely'),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(_isSignUp ? 'Already have an account?' : 'New to CivicVote?'),
                        TextButton(
                          onPressed: _isBusy ? null : widget.onSwitch,
                          child: Text(_isSignUp ? 'Sign in' : 'Create account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Passwords are handled by Supabase Auth and are never stored in a voter profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _isEmail(String value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
