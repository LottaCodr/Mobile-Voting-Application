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
  Stream<void> get passwordRecoveryEvents;

  Future<void> signIn({required String email, required String password});
  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  });
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String password);
  Future<MfaStatus> getMfaStatus();
  Future<List<MfaFactor>> listMfaFactors();
  Future<MfaEnrollment> enrollTotp({required String friendlyName});
  Future<void> verifyTotpEnrollment({required String factorId, required String code});
  Future<void> challengeTotp({required String factorId, required String code});
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
  Stream<void> get passwordRecoveryEvents {
    return _client.auth.onAuthStateChange
        .where((state) => state.event == AuthChangeEvent.passwordRecovery)
        .map<void>((_) {});
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
      final redirect = passwordResetRedirect.trim();
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirect.isEmpty ? null : redirect,
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
  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('Your password could not be updated. Please try again.');
    }
  }

  @override
  Future<MfaStatus> getMfaStatus() async {
    try {
      final dynamic assurance = await _client.auth.mfa.getAuthenticatorAssuranceLevel();
      final factors = await listMfaFactors();
      return MfaStatus.fromValues(
        currentLevel: assurance.currentLevel,
        nextLevel: assurance.nextLevel,
        hasVerifiedFactor: factors.any((factor) => factor.isVerified),
      );
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('Your multi-factor security status is unavailable right now.');
    }
  }

  @override
  Future<List<MfaFactor>> listMfaFactors() async {
    try {
      final dynamic factors = await _client.auth.mfa.listFactors();
      final raw = factors.all;
      if (raw is! Iterable) return const <MfaFactor>[];
      return raw
          .map<MfaFactor>((dynamic factor) {
            return MfaFactor(
              id: factor.id?.toString() ?? '',
              friendlyName: factor.friendlyName?.toString() ?? 'Authenticator app',
              status: factor.status?.toString() ?? 'unverified',
            );
          })
          .where((factor) => factor.id.isNotEmpty)
          .toList();
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('Your authenticator methods are unavailable right now.');
    }
  }

  @override
  Future<MfaEnrollment> enrollTotp({required String friendlyName}) async {
    try {
      final dynamic enrollment = await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        friendlyName: friendlyName,
      );
      final dynamic totp = enrollment.totp;
      final qrCode = totp?.qrCode?.toString() ?? '';
      final secret = totp?.secret?.toString() ?? '';
      final factorId = enrollment.id?.toString() ?? '';
      if (factorId.isEmpty || qrCode.isEmpty || secret.isEmpty) {
        throw const AuthFailure(
          'The authenticator setup details were incomplete. Please try again.',
        );
      }
      return MfaEnrollment(factorId: factorId, qrCode: qrCode, secret: secret);
    } on AuthFailure {
      rethrow;
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('We could not start authenticator setup. Please try again.');
    }
  }

  @override
  Future<void> verifyTotpEnrollment({required String factorId, required String code}) async {
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('That authenticator code could not be verified. Try a new code.');
    }
  }

  @override
  Future<void> challengeTotp({required String factorId, required String code}) async {
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
    } on AuthException catch (error) {
      throw AuthFailure(_friendlyAuthMessage(error));
    } catch (_) {
      throw const AuthFailure('That authenticator code could not be verified. Try a new code.');
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
