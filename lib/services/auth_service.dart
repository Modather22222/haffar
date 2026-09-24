import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// Result of a sign-up attempt.
class SignUpResult {
  /// True when Supabase requires the user to confirm their email first
  /// (no session yet). False when a session was created immediately.
  final bool needsConfirmation;
  final User? user;

  const SignUpResult({required this.needsConfirmation, this.user});
}

/// Email/password authentication against Supabase Auth.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  bool get isSignedIn => _client.auth.currentSession != null;

  User? get currentUser => _client.auth.currentUser;

  /// Stream of auth state changes (signedIn / signedOut / tokenRefreshed / …).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Create an email/password account. Optional [displayName] is stored on
  /// the user metadata and used by the profile bootstrap when available.
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    AppLog.info('auth: signUp start email=$email');
    final res = await _client.auth.signUp(
      email: email,
      password: password,
      data: displayName == null ? null : {'display_name': displayName},
    );
    final needsConfirmation = res.session == null;
    AppLog.info(
      'auth: signUp OK needsConfirmation=$needsConfirmation '
      'user=${res.user?.id}',
    );
    return SignUpResult(needsConfirmation: needsConfirmation, user: res.user);
  }

  /// Sign in with email + password. Throws [AuthException] on failure.
  Future<Session> signInWithPassword({
    required String email,
    required String password,
  }) async {
    AppLog.info('auth: signInWithPassword start email=$email');
    final res = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final session = res.session;
    if (session == null) {
      throw AuthException('Sign-in returned no session');
    }
    AppLog.info('auth: signInWithPassword OK user=${session.user.id}');
    return session;
  }

  /// Send a password-reset email. [redirectTo] should be an approved
  /// redirect URL configured in Supabase Auth settings.
  Future<void> resetPasswordForEmail(String email, {String? redirectTo}) async {
    AppLog.info('auth: resetPasswordForEmail email=$email');
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  Future<void> signOut() async {
    AppLog.info('auth: signOut start');
    await _client.auth.signOut();
    AppLog.info('auth: signOut OK');
  }

  /// Restore an existing session if present. Does NOT create anonymous
  /// sessions — callers should route unauthenticated users to sign-up/in.
  Future<bool> restoreSession() async {
    if (isSignedIn) {
      AppLog.info('auth: existing session user=${currentUser?.id}');
      return true;
    }
    try {
      // getSessionFromUrl / currentSession is populated by Supabase.initialize
      // from local storage; force a refresh attempt for stale tokens.
      await _client.auth.getSession();
    } catch (e, st) {
      AppLog.error('auth: getSession FAILED', e, st);
      return false;
    }
    final ok = isSignedIn;
    AppLog.info('auth: restoreSession ok=$ok');
    return ok;
  }
}
