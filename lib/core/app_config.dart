import 'package:supabase_flutter/supabase_flutter.dart';

/// Build-time configuration only. Never place a service-role key in this app.
///
/// Example:
/// flutter run --dart-define=SUPABASE_URL=https://example.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...
class AppConfiguration {
  const AppConfiguration({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.passwordResetRedirect,
  });

  static const fromEnvironment = AppConfiguration(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    passwordResetRedirect: String.fromEnvironment('PASSWORD_RESET_REDIRECT'),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String passwordResetRedirect;

  bool get isConfigured {
    final uri = Uri.tryParse(supabaseUrl);
    return uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        supabasePublishableKey.trim().isNotEmpty;
  }
}

/// Starts Supabase once before the widget tree is created.
///
/// A missing configuration deliberately opens the clearly labelled local demo.
/// A malformed configured backend fails closed instead of silently submitting
/// anything to a local store.
class SupabaseBootstrap {
  SupabaseBootstrap._();

  static final AppConfiguration configuration = AppConfiguration.fromEnvironment;
  static bool _initialized = false;
  static Object? _initializationError;

  static bool get isInitialized => _initialized;
  static Object? get initializationError => _initializationError;

  static Future<void> initialize() async {
    if (!configuration.isConfigured || _initialized) return;

    try {
      await Supabase.initialize(
        url: configuration.supabaseUrl,
        publishableKey: configuration.supabasePublishableKey,
      );
      _initialized = true;
    } catch (error) {
      _initializationError = error;
    }
  }
}
