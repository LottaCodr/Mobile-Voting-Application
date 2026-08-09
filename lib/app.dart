import 'package:flutter/material.dart';

import 'core/app_scope.dart';
import 'core/app_theme.dart';
import 'data/app_services.dart';
import 'state/app_controller.dart';
import 'ui/screens/app_shell.dart';
import 'ui/screens/service_unavailable_screen.dart';
import 'ui/screens/signed_out_screen.dart';
import 'ui/widgets/common.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.services});

  final AppServices? services;

  @override
  Widget build(BuildContext context) {
    return CivicVoteApp(services: services ?? AppServices.create());
  }
}

class CivicVoteApp extends StatefulWidget {
  const CivicVoteApp({super.key, required this.services});

  final AppServices services;

  @override
  State<CivicVoteApp> createState() => _CivicVoteAppState();
}

class _CivicVoteAppState extends State<CivicVoteApp> {
  late final AppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AppController(widget.services);
    _controller.bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'CivicVote',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            switch (_controller.phase) {
              case SessionPhase.loading:
                return const _AppLoadingScreen();
              case SessionPhase.unavailable:
                return const ServiceUnavailableScreen();
              case SessionPhase.signedOut:
                return const SignedOutScreen();
              case SessionPhase.authenticated:
              case SessionPhase.demo:
                return const AppShell();
            }
          },
        ),
      ),
    );
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
            children: [
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
