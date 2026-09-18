import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

/// Handles authentication — anonymous sign-in as the default identity.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  bool get isSignedIn => _client.auth.currentSession != null;

  /// Restore the existing session or sign in anonymously.
  /// Returns false when remote identity is unavailable (local-only mode).
  Future<bool> ensureSignedIn() async {
    if (isSignedIn) {
      AppLog.info('auth: existing session');
      return true;
    }
    try {
      AppLog.info('auth: signInAnonymously start');
      await _client.auth.signInAnonymously();
      AppLog.info('auth: signInAnonymously OK');
      return true;
    } catch (e, st) {
      AppLog.error('auth: signInAnonymously FAILED', e, st);
      return false;
    }
  }
}
