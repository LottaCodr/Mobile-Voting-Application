import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_theme.dart';
import 'data/app_services.dart';
import 'state/app_state.dart';
import 'ui/screens/app_shell.dart';
import 'ui/screens/password_reset_screen.dart';
import 'ui/screens/service_unavailable_screen.dart';
import 'ui/screens/signed_out_screen.dart';
import 'ui/widgets/common.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.services});

  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appServicesProvider.overrideWithValue(services ?? AppServices.create())],
      child: const CivicVoteApp(),
    );
  }
}

class CivicVoteApp extends ConsumerWidget {
  const CivicVoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'CivicVote',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends ConsumerWidget {
  const _AppEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    if (session.needsPasswordReset) return const PasswordResetScreen();
    return switch (session.phase) {
      SessionPhase.loading => const _AppLoadingScreen(),
      SessionPhase.unavailable => const ServiceUnavailableScreen(),
      SessionPhase.signedOut => const SignedOutScreen(),
      SessionPhase.authenticated || SessionPhase.demo => const AppShell(),
    };
  }
}

class _AppLoadingScreen extends StatelessWidget {
  const _AppLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageFrame(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const AppLogo(),
              const SizedBox(height: 28),
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 14),
              Text(
                'Preparing your secure voter portal…',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
