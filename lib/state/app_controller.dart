import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/app_services.dart';
import '../data/auth_gateway.dart';
import '../data/demo_voting_repository.dart';
import '../domain/models.dart';

enum SessionPhase { loading, signedOut, authenticated, demo, unavailable }

class AppController extends ChangeNotifier {
  AppController(this.services);

  final AppServices services;
  StreamSubscription<AppUser?>? _authSubscription;
  bool _isDisposed = false;

  SessionPhase _phase = SessionPhase.loading;
  AppUser? _user;
  VoterProfile? _profile;

  SessionPhase get phase => _phase;
  AppUser? get user => _user;
  VoterProfile? get profile => _profile;
  bool get isDemo => _phase == SessionPhase.demo;
  bool get isActiveSession => _phase == SessionPhase.authenticated || _phase == SessionPhase.demo;

  Future<void> bootstrap() async {
    if (services.isUnavailable) {
      _phase = SessionPhase.unavailable;
      _notify();
      return;
    }

    if (services.isDemo) {
      _phase = SessionPhase.signedOut;
      _notify();
      return;
    }

    final auth = services.auth;
    if (auth == null) {
      _phase = SessionPhase.unavailable;
      _notify();
      return;
    }

    _authSubscription = auth.authStateChanges.listen((user) {
      unawaited(_applyAuthenticatedUser(user));
    });
    await _applyAuthenticatedUser(auth.currentUser, notify: false);
    if (_phase == SessionPhase.loading) {
      _phase = _user == null ? SessionPhase.signedOut : SessionPhase.authenticated;
    }
    _notify();
  }

  Future<void> enterDemo() async {
    _user = DemoVotingRepository.demoUser;
    _profile = DemoVotingRepository.demoProfile;
    _phase = SessionPhase.demo;
    _notify();
  }

  Future<void> leaveDemo() async {
    _user = null;
    _profile = null;
    _phase = SessionPhase.signedOut;
    _notify();
  }

  Future<void> signIn({required String email, required String password}) async {
    final auth = _requireAuth();
    await auth.signIn(email: email, password: password);
    await _applyAuthenticatedUser(auth.currentUser);
  }

  Future<SignUpResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final auth = _requireAuth();
    final result = await auth.signUp(fullName: fullName, email: email, password: password);
    // With email confirmation enabled Supabase returns no session. Do not let a
    // cached user object look like a signed-in, verified voting session.
    await _applyAuthenticatedUser(result.requiresEmailConfirmation ? null : auth.currentUser);
    return result;
  }

  Future<void> resetPassword(String email) => _requireAuth().resetPassword(email);

  Future<void> signOut() async {
    if (isDemo) {
      return leaveDemo();
    }
    final auth = _requireAuth();
    await auth.signOut();
    await _applyAuthenticatedUser(null);
  }

  Future<void> refreshProfile() async {
    final user = _user;
    if (user == null) return;
    await _loadProfileFor(user, notify: true);
  }

  AuthGateway _requireAuth() {
    final auth = services.auth;
    if (auth == null) {
      throw const AuthFailure('Account access is unavailable in the local demo.');
    }
    return auth;
  }

  Future<void> _applyAuthenticatedUser(AppUser? user, {bool notify = true}) async {
    _user = user;
    if (user == null) {
      _profile = null;
      _phase = SessionPhase.signedOut;
      if (notify) _notify();
      return;
    }

    _phase = SessionPhase.authenticated;
    await _loadProfileFor(user, notify: notify);
  }

  Future<void> _loadProfileFor(AppUser user, {required bool notify}) async {
    try {
      _profile = await services.voting.loadProfile(user.id);
    } catch (_) {
      // Auth remains usable if the profile trigger has not completed yet.
      _profile = null;
    }
    if (notify) _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
