import 'package:flutter/material.dart';

import '../../core/app_scope.dart';
import '../../core/app_theme.dart';
import '../../data/app_services.dart';
import '../../data/auth_gateway.dart';
import '../widgets/common.dart';

enum _AuthView { welcome, signIn, signUp }

class SignedOutScreen extends StatefulWidget {
  const SignedOutScreen({super.key});

  @override
  State<SignedOutScreen> createState() => _SignedOutScreenState();
}

class _SignedOutScreenState extends State<SignedOutScreen> {
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

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.onSignIn, required this.onSignUp});

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final isDemo = controller.services.mode == AppDataMode.demo;

    return Scaffold(
      body: PageFrame(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const AppLogo(),
                    const SizedBox(height: 56),
                    Semantics(
                      container: true,
                      label: isDemo ? 'CivicVote product preview' : 'CivicVote secure voter portal',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDemo ? AppColors.goldPale : AppColors.tealPale,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isDemo ? Icons.science_outlined : Icons.lock_outline_rounded,
                              size: 16,
                              color: isDemo ? AppColors.gold : AppColors.teal,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              isDemo ? 'PRODUCT PREVIEW' : 'SECURE VOTER PORTAL',
                              style: TextStyle(
                                color: isDemo ? AppColors.gold : AppColors.teal,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.7,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          ? 'Explore an accessible, fictional ballot before connecting your own Supabase project.'
                          : 'Review official ballot information, cast a verified vote, and follow published results in one calm place.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted, height: 1.55),
                    ),
                    const SizedBox(height: 32),
                    const _PromiseRow(
                      icon: Icons.fact_check_outlined,
                      title: 'Review before you submit',
                      description: 'Clear candidate information and an explicit confirmation step.',
                    ),
                    const SizedBox(height: 18),
                    const _PromiseRow(
                      icon: Icons.verified_user_outlined,
                      title: 'Verification-aware',
                      description: 'Your eligibility status is visible before a ballot opens.',
                    ),
                    const SizedBox(height: 18),
                    const _PromiseRow(
                      icon: Icons.visibility_off_outlined,
                      title: 'Privacy by design',
                      description: 'The client never reads a voter-to-candidate record.',
                    ),
                    const SizedBox(height: 38),
                    if (isDemo) ...[
                      FilledButton.icon(
                        key: const Key('exploreDemoButton'),
                        onPressed: controller.enterDemo,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Explore demo ballot'),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nothing in demo mode is an official vote.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                      ),
                    ] else ...[
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
            );
          },
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
      children: [
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
            children: [
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

class _AuthPanel extends StatefulWidget {
  const _AuthPanel({required this.mode, required this.onBack, required this.onSwitch});

  final _AuthView mode;
  final VoidCallback onBack;
  final VoidCallback onSwitch;

  @override
  State<_AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<_AuthPanel> {
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
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    setState(() => _isBusy = true);
    final controller = AppScope.of(context);

    try {
      if (_isSignUp) {
        final result = await controller.signUp(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (!mounted) return;
        if (result.requiresEmailConfirmation) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Check your email to confirm your new account, then sign in.'),
            ),
          );
          widget.onSwitch();
        }
      } else {
        await controller.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
    } on AuthFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (!_isEmail(email)) {
      _showMessage('Enter your email address first, then try again.');
      return;
    }
    setState(() => _isBusy = true);
    try {
      await AppScope.of(context).resetPassword(email);
      if (mounted) {
        _showMessage('If an account exists for that address, a reset email is on its way.');
      }
    } on AuthFailure catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create your voter account' : 'Welcome back';
    final subtitle = _isSignUp
        ? 'Use details that match your eligibility record. Verification happens separately.'
        : 'Sign in to view your eligible elections and ballot status.';

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
                  children: [
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
                    if (_isSignUp) ...[
                      TextFormField(
                        controller: _fullNameController,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().length < 2) return 'Enter your full name.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
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
                      autofillHints: [
                        _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
                      ],
                      onFieldSubmitted: (_) => _isSignUp ? null : _submit(),
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
                      validator: (value) {
                        if ((value ?? '').length < 8) return 'Use at least 8 characters.';
                        return null;
                      },
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onFieldSubmitted: (_) => _submit(),
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
                        validator: (value) {
                          if (value != _passwordController.text) return 'Passwords do not match.';
                          return null;
                        },
                      ),
                    ],
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isBusy ? null : _resetPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isBusy ? null : _submit,
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
                      children: [
                        Text(_isSignUp ? 'Already have an account?' : 'New to CivicVote?'),
                        TextButton(
                          onPressed: _isBusy ? null : widget.onSwitch,
                          child: Text(_isSignUp ? 'Sign in' : 'Create account'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Account passwords are handled by Supabase Auth and are never stored in the voter profile.',
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

bool _isEmail(String value) {
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
}
