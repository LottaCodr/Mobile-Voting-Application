import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class SignUpResult {
  const SignUpResult({required this.requiresEmailConfirmation});

  final bool requiresEmailConfirmation;
}

abstract interface class AuthGateway {
  AppUser? get currentUser;
  Stream<AppUser?> get authStateChanges;

  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> resetPassword(String email);
  Future<void> signOut();
}

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client, {required this.passwordResetRedirect});

  final SupabaseClient _client;
  final String passwordResetRedirect;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    return user == null ? null : _toAppUser(user);
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((state) {
      final user = state.session?.user ?? _client.auth.currentUser;
      return user == null ? null : _toAppUser(user);
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('We could not sign you in. Please try again.');
    }
  }

  @override
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{'full_name': fullName},
      );
      return SignUpResult(requiresEmailConfirmation: response.session == null);
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('We could not create your account. Please try again.');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      final redirect = passwordResetRedirect.trim();
      if (redirect.isEmpty) {
        await _client.auth.resetPasswordForEmail(email);
      } else {
        await _client.auth.resetPasswordForEmail(email, redirectTo: redirect);
      }
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('We could not send the reset email. Please try again.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('We could not sign you out. Please try again.');
    }
  }

  AppUser _toAppUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final name = (metadata['full_name'] ?? metadata['name'] ?? '').toString().trim();
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: name.isEmpty ? 'Voter' : name,
    );
  }
}

String _friendlyAuthMessage(AuthException error) {
  final message = error.message.toLowerCase();
  if (message.contains('invalid login credentials')) {
    return 'The email or password does not match our records.';
  }
  if (message.contains('email not confirmed')) {
    return 'Please confirm your email before signing in.';
  }
  if (message.contains('already registered') || message.contains('already been registered')) {
    return 'An account already exists for that email address.';
  }
  if (message.contains('password')) {
    return 'Use a stronger password and try again.';
  }
  return error.message.isEmpty ? 'Authentication could not be completed.' : error.message;
}
