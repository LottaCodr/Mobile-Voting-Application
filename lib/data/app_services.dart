import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/app_config.dart';
import 'auth_gateway.dart';
import 'demo_voting_repository.dart';
import 'voting_repository.dart';

enum AppDataMode { demo, supabase, unavailable }

/// Single composition point for the app's dependencies.
class AppServices {
  const AppServices._({
    required this.mode,
    required this.voting,
    required this.configuration,
    this.auth,
  });

  final AppDataMode mode;
  final VotingRepository voting;
  final AppConfiguration configuration;
  final AuthGateway? auth;

  bool get isDemo => mode == AppDataMode.demo;
  bool get isUnavailable => mode == AppDataMode.unavailable;

  factory AppServices.create() {
    final configuration = SupabaseBootstrap.configuration;

    if (configuration.isConfigured) {
      if (SupabaseBootstrap.isInitialized) {
        final client = Supabase.instance.client;
        return AppServices._(
          mode: AppDataMode.supabase,
          voting: SupabaseVotingRepository(client),
          auth: SupabaseAuthGateway(
            client,
            passwordResetRedirect: configuration.passwordResetRedirect,
          ),
          configuration: configuration,
        );
      }

      // A configured endpoint must never degrade into a device-local ballot.
      return AppServices._(
        mode: AppDataMode.unavailable,
        voting: DemoVotingRepository(),
        configuration: configuration,
      );
    }

    return AppServices._(
      mode: AppDataMode.demo,
      voting: DemoVotingRepository(),
      configuration: configuration,
    );
  }
}
