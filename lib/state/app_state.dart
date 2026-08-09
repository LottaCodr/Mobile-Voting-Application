import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_services.dart';
import '../data/auth_gateway.dart';
import '../data/demo_voting_repository.dart';
import '../data/voting_repository.dart';
import '../domain/models.dart';

enum SessionPhase { loading, signedOut, authenticated, demo, unavailable }

@immutable
class AppSession {
  const AppSession({
    required this.phase,
    this.user,
    this.profile,
    this.roles = const <AppRole>[],
    this.mfaStatus,
    this.needsPasswordReset = false,
  });

  const AppSession.loading() : this(phase: SessionPhase.loading);
  const AppSession.signedOut() : this(phase: SessionPhase.signedOut);
  const AppSession.unavailable() : this(phase: SessionPhase.unavailable);

  final SessionPhase phase;
  final AppUser? user;
  final VoterProfile? profile;
  final List<AppRole> roles;
  final MfaStatus? mfaStatus;
  final bool needsPasswordReset;

  bool get isDemo => phase == SessionPhase.demo;
  bool get isActive => phase == SessionPhase.authenticated || phase == SessionPhase.demo;
  bool get canAdminister => roles.any(
    (role) =>
        role == AppRole.administrator ||
        role == AppRole.electionManager ||
        role == AppRole.verifier ||
        role == AppRole.auditor,
  );
  bool get canVerify =>
      roles.any((role) => role == AppRole.administrator || role == AppRole.verifier);
  bool get canManageElections =>
      roles.any((role) => role == AppRole.administrator || role == AppRole.electionManager);

  AppSession copyWith({
    SessionPhase? phase,
    AppUser? user,
    VoterProfile? profile,
    List<AppRole>? roles,
    MfaStatus? mfaStatus,
    bool clearUser = false,
    bool clearProfile = false,
    bool clearMfaStatus = false,
    bool? needsPasswordReset,
  }) {
    return AppSession(
      phase: phase ?? this.phase,
      user: clearUser ? null : user ?? this.user,
      profile: clearProfile ? null : profile ?? this.profile,
      roles: roles ?? this.roles,
      mfaStatus: clearMfaStatus ? null : mfaStatus ?? this.mfaStatus,
      needsPasswordReset: needsPasswordReset ?? this.needsPasswordReset,
    );
  }
}

final appServicesProvider = Provider<AppServices>((ref) {
  throw UnimplementedError('AppServices must be overridden at the app root.');
});

final votingRepositoryProvider = Provider<VotingRepository>(
  (ref) => ref.watch(appServicesProvider).voting,
);

final authGatewayProvider = Provider<AuthGateway?>((ref) => ref.watch(appServicesProvider).auth);

final sessionProvider = NotifierProvider<SessionNotifier, AppSession>(SessionNotifier.new);

class SessionNotifier extends Notifier<AppSession> {
  StreamSubscription<AppUser?>? _authSubscription;
  StreamSubscription<void>? _passwordRecoverySubscription;

  @override
  AppSession build() {
    ref.onDispose(() {
      _authSubscription?.cancel();
      _passwordRecoverySubscription?.cancel();
    });
    unawaited(_bootstrap());
    return const AppSession.loading();
  }

  Future<void> _bootstrap() async {
    final services = ref.read(appServicesProvider);
    if (services.isUnavailable) {
      state = const AppSession.unavailable();
      return;
    }
    if (services.isDemo) {
      state = const AppSession.signedOut();
      return;
    }

    final auth = ref.read(authGatewayProvider);
    if (auth == null) {
      state = const AppSession.unavailable();
      return;
    }

    _authSubscription = auth.authStateChanges.listen(
      (user) => unawaited(_applyAuthenticatedUser(user)),
      onError: (_, __) {
        // A token refresh can fail while offline. Preserve the last valid
        // session; repository calls surface a recoverable error state instead.
      },
    );
    _passwordRecoverySubscription = auth.passwordRecoveryEvents.listen(
      (_) => state = state.copyWith(needsPasswordReset: true),
      onError: (_, __) {},
    );
    await _applyAuthenticatedUser(auth.currentUser);
  }

  Future<void> enterDemo() async {
    state = const AppSession(
      phase: SessionPhase.demo,
      user: DemoVotingRepository.demoUser,
      profile: DemoVotingRepository.demoProfile,
      roles: <AppRole>[],
      mfaStatus: MfaStatus(currentLevel: 'aal2', nextLevel: 'aal2', hasVerifiedFactor: true),
    );
    _refreshSessionDependencies();
  }

  Future<void> leaveDemo() async {
    state = const AppSession.signedOut();
    _refreshSessionDependencies();
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
    await _applyAuthenticatedUser(result.requiresEmailConfirmation ? null : auth.currentUser);
    return result;
  }

  Future<void> resetPassword(String email) => _requireAuth().resetPassword(email);

  Future<void> completePasswordReset(String password) async {
    await _requireAuth().updatePassword(password);
    state = state.copyWith(needsPasswordReset: false);
  }

  Future<void> signOut() async {
    if (state.isDemo) return leaveDemo();
    final auth = _requireAuth();
    await auth.signOut();
    await _applyAuthenticatedUser(null);
  }

  Future<void> refreshProfile() async {
    final user = state.user;
    if (user == null) return;
    await _applyAuthenticatedUser(user);
  }

  Future<MfaStatus> refreshMfaStatus() async {
    if (state.isDemo) return state.mfaStatus!;
    final status = await _requireAuth().getMfaStatus();
    state = state.copyWith(mfaStatus: status);
    return status;
  }

  Future<List<MfaFactor>> listMfaFactors() {
    if (state.isDemo) return Future<List<MfaFactor>>.value(const <MfaFactor>[]);
    return _requireAuth().listMfaFactors();
  }

  Future<MfaEnrollment> enrollTotp(String friendlyName) =>
      _requireAuth().enrollTotp(friendlyName: friendlyName);

  Future<void> verifyTotpEnrollment({required String factorId, required String code}) async {
    await _requireAuth().verifyTotpEnrollment(factorId: factorId, code: code);
    await refreshMfaStatus();
  }

  Future<void> challengeTotp({required String factorId, required String code}) async {
    await _requireAuth().challengeTotp(factorId: factorId, code: code);
    await refreshMfaStatus();
  }

  AuthGateway _requireAuth() {
    final auth = ref.read(authGatewayProvider);
    if (auth == null) {
      throw const AuthFailure('Account access is unavailable in the local demo.');
    }
    return auth;
  }

  Future<void> _applyAuthenticatedUser(AppUser? user) async {
    if (user == null) {
      state = const AppSession.signedOut();
      _refreshSessionDependencies();
      return;
    }

    final repository = ref.read(votingRepositoryProvider);
    VoterProfile? profile;
    List<AppRole> roles = const <AppRole>[];
    MfaStatus? mfaStatus;
    try {
      profile = await repository.loadProfile(user.id);
    } catch (_) {
      profile = null;
    }
    try {
      roles = await repository.loadMyRoles();
    } catch (_) {
      roles = const <AppRole>[];
    }
    try {
      mfaStatus = await _requireAuth().getMfaStatus();
    } catch (_) {
      mfaStatus = null;
    }

    state = AppSession(
      phase: SessionPhase.authenticated,
      user: user,
      profile: profile,
      roles: roles,
      mfaStatus: mfaStatus,
      needsPasswordReset: state.needsPasswordReset,
    );
    _refreshSessionDependencies();
  }

  void _refreshSessionDependencies() {
    ref.invalidate(electionsProvider);
    ref.invalidate(notificationPreferencesProvider);
    ref.invalidate(notificationsProvider);
  }
}

final electionsProvider = FutureProvider<List<Election>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isActive) return const <Election>[];
  return ref.watch(votingRepositoryProvider).loadElections();
});

final contestsProvider = FutureProvider.family<List<BallotContest>, String>((
  ref,
  electionId,
) async {
  return ref.watch(votingRepositoryProvider).loadContests(electionId);
});

final candidatesProvider = FutureProvider.family<List<Candidate>, String>((ref, electionId) async {
  return ref.watch(votingRepositoryProvider).loadCandidates(electionId);
});

final ballotStatusProvider = FutureProvider.family<BallotSubmissionStatus, String>((
  ref,
  electionId,
) async {
  return ref.watch(votingRepositoryProvider).loadSubmissionStatus(electionId);
});

final resultsProvider = FutureProvider.family<List<ElectionResult>, String>((
  ref,
  electionId,
) async {
  return ref.watch(votingRepositoryProvider).loadResults(electionId);
});

final liveResultsProvider = StreamProvider.family<List<ElectionResult>, String>((ref, electionId) {
  return ref.watch(votingRepositoryProvider).watchResults(electionId);
});

final notificationPreferencesProvider = FutureProvider<NotificationPreferences>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.isActive) {
    return const NotificationPreferences(
      electionReminders: true,
      verificationUpdates: true,
      resultsUpdates: true,
    );
  }
  return ref.watch(votingRepositoryProvider).loadNotificationPreferences();
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final session = ref.watch(sessionProvider);
  if (!session.isActive) return Stream<List<AppNotification>>.value(const <AppNotification>[]);
  return ref.watch(votingRepositoryProvider).watchNotifications();
});

final adminMetricsProvider = FutureProvider<AdminMetrics>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.canAdminister) {
    throw const RepositoryFailure('Administrative access is required.');
  }
  return ref.watch(votingRepositoryProvider).loadAdminMetrics();
});

final auditEventsProvider = FutureProvider<List<AuditEvent>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.roles.any((role) => role == AppRole.administrator || role == AppRole.auditor)) {
    throw const RepositoryFailure('Audit access is required.');
  }
  return ref.watch(votingRepositoryProvider).loadRecentAuditEvents();
});

final managedElectionsProvider = FutureProvider<List<Election>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.canAdminister) {
    throw const RepositoryFailure('Authority access is required.');
  }
  return ref.watch(votingRepositoryProvider).loadManagedElections();
});

final pendingVotersProvider = FutureProvider<List<AdminVoter>>((ref) async {
  final session = ref.watch(sessionProvider);
  if (!session.canVerify) {
    throw const RepositoryFailure('Verification access is required.');
  }
  return ref.watch(votingRepositoryProvider).loadPendingVoters();
});

@immutable
class BallotDraft {
  const BallotDraft({required this.electionId, this.choices = const <String, String>{}});

  final String? electionId;
  final Map<String, String> choices;

  BallotDraft forElection(String electionId) {
    if (this.electionId == electionId) return this;
    return BallotDraft(electionId: electionId);
  }

  BallotDraft select({
    required String electionId,
    required String contestId,
    required String candidateId,
  }) {
    final base = forElection(electionId);
    return BallotDraft(
      electionId: electionId,
      choices: <String, String>{...base.choices, contestId: candidateId},
    );
  }
}

final ballotDraftProvider = NotifierProvider<BallotDraftNotifier, BallotDraft>(
  BallotDraftNotifier.new,
);

class BallotDraftNotifier extends Notifier<BallotDraft> {
  @override
  BallotDraft build() => const BallotDraft(electionId: null);

  void prepare(String electionId) => state = state.forElection(electionId);

  void select({
    required String electionId,
    required String contestId,
    required String candidateId,
  }) {
    state = state.select(electionId: electionId, contestId: contestId, candidateId: candidateId);
  }

  void clear(String electionId) {
    if (state.electionId == electionId) {
      state = BallotDraft(electionId: electionId);
    }
  }
}
