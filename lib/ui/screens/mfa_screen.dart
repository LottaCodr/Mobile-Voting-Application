import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_theme.dart';
import '../../data/auth_gateway.dart';
import '../../domain/models.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';

class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({super.key});

  @override
  ConsumerState<MfaScreen> createState() => _MfaScreenState();
}

class _MfaScreenState extends ConsumerState<MfaScreen> {
  final _nameController = TextEditingController(text: 'My authenticator app');
  final _codeController = TextEditingController();
  Future<List<MfaFactor>>? _factors;
  MfaEnrollment? _enrollment;
  MfaFactor? _selectedFactor;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _factors = ref.read(sessionProvider.notifier).listMfaFactors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _factors = ref.read(sessionProvider.notifier).listMfaFactors());
    await _factors;
  }

  Future<void> _startEnrollment() async {
    setState(() => _busy = true);
    try {
      final enrollment = await ref
          .read(sessionProvider.notifier)
          .enrollTotp(
            _nameController.text.trim().isEmpty ? 'Authenticator app' : _nameController.text.trim(),
          );
      if (mounted) {
        setState(() {
          _enrollment = enrollment;
          _codeController.clear();
        });
      }
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyEnrollment() async {
    final enrollment = _enrollment;
    if (enrollment == null || _codeController.text.trim().length < 6) {
      _message('Enter the six-digit code shown in your authenticator app.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .verifyTotpEnrollment(factorId: enrollment.factorId, code: _codeController.text.trim());
      if (mounted) {
        _message('Multi-factor verification is active for this session.');
        setState(() => _enrollment = null);
        await _reload();
      }
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _challengeExisting() async {
    final factor = _selectedFactor;
    if (factor == null || _codeController.text.trim().length < 6) {
      _message('Choose an authenticator and enter its current six-digit code.');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(sessionProvider.notifier)
          .challengeTotp(factorId: factor.id, code: _codeController.text.trim());
      if (mounted) _message('Second-factor verification is active for this session.');
    } on AuthFailure catch (error) {
      if (mounted) _message(error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final status = session.mfaStatus;
    return Scaffold(
      appBar: AppBar(title: const Text('Multi-factor security')),
      body: PageFrame(
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: status?.isElevated == true ? AppColors.tealPale : AppColors.bluePale,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    status?.isElevated == true
                        ? Icons.verified_user_rounded
                        : Icons.security_rounded,
                    color: status?.isElevated == true ? AppColors.teal : AppColors.blueDark,
                    size: 30,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    status?.isElevated == true
                        ? 'Second factor verified for this session'
                        : 'Add or verify an authenticator',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    status?.isElevated == true
                        ? 'Some election authorities require this higher assurance level immediately before ballot submission.'
                        : 'An authenticator app helps protect your account. Authority-assigned elections can require this step before submission.',
                    style: const TextStyle(color: AppColors.inkMuted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_enrollment != null)
              _EnrollmentStep(
                enrollment: _enrollment!,
                codeController: _codeController,
                busy: _busy,
                onVerify: () => unawaited(_verifyEnrollment()),
                onCancel: () => setState(() => _enrollment = null),
              )
            else
              FutureBuilder<List<MfaFactor>>(
                future: _factors,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const LoadingState(label: 'Loading authenticator methods');
                  }
                  if (snapshot.hasError) {
                    return InlineError(
                      message: 'Authenticator methods are unavailable right now.',
                      onRetry: () => _reload(),
                    );
                  }
                  final factors = snapshot.data ?? const <MfaFactor>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (factors.isNotEmpty) ...<Widget>[
                        const SectionHeading(
                          title: 'Verify this session',
                          subtitle:
                              'Use a current code from an enrolled authenticator before a protected action.',
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: <Widget>[
                                DropdownButtonFormField<String>(
                                  value: _selectedFactor?.id,
                                  decoration: const InputDecoration(
                                    labelText: 'Authenticator',
                                    prefixIcon: Icon(Icons.phonelink_lock_outlined),
                                  ),
                                  items: <DropdownMenuItem<String>>[
                                    for (final factor in factors)
                                      DropdownMenuItem<String>(
                                        value: factor.id,
                                        child: Text(
                                          '${factor.friendlyName} · ${factor.isVerified ? 'verified' : 'pending'}',
                                        ),
                                      ),
                                  ],
                                  onChanged: (id) => setState(
                                    () => _selectedFactor = factors
                                        .where((factor) => factor.id == id)
                                        .firstOrNull,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _CodeField(controller: _codeController),
                                const SizedBox(height: 14),
                                FilledButton.icon(
                                  onPressed: _busy ? null : () => unawaited(_challengeExisting()),
                                  icon: const Icon(Icons.verified_user_outlined),
                                  label: _busy
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Verify this session'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      const SectionHeading(
                        title: 'Add an authenticator app',
                        subtitle:
                            'Scan a QR code with a trusted TOTP authenticator, then verify the first code.',
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: <Widget>[
                              TextField(
                                controller: _nameController,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  labelText: 'Authenticator name',
                                  hintText: 'For example, Personal phone',
                                  prefixIcon: Icon(Icons.smartphone_outlined),
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: _busy ? null : () => unawaited(_startEnrollment()),
                                icon: const Icon(Icons.qr_code_rounded),
                                label: const Text('Generate secure setup code'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _EnrollmentStep extends StatelessWidget {
  const _EnrollmentStep({
    required this.enrollment,
    required this.codeController,
    required this.busy,
    required this.onVerify,
    required this.onCancel,
  });

  final MfaEnrollment enrollment;
  final TextEditingController codeController;
  final bool busy;
  final VoidCallback onVerify;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeading(
          title: 'Scan and verify',
          subtitle: 'Use a TOTP authenticator app. Never share the setup secret or one-time codes.',
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: QrImageView(data: enrollment.qrCode, version: QrVersions.auto, size: 190),
                ),
                const SizedBox(height: 18),
                const Text('Can’t scan it? Enter this setup key in your authenticator app:'),
                const SizedBox(height: 8),
                SelectableText(
                  enrollment.secret,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 18),
                _CodeField(controller: codeController),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: busy ? null : onVerify,
                  icon: const Icon(Icons.verified_rounded),
                  label: busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Verify and activate'),
                ),
                TextButton(onPressed: busy ? null : onCancel, child: const Text('Cancel setup')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CodeField extends StatelessWidget {
  const _CodeField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      maxLength: 8,
      decoration: const InputDecoration(
        labelText: 'Authenticator code',
        hintText: '000000',
        counterText: '',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    for (final item in this) {
      return item;
    }
    return null;
  }
}
