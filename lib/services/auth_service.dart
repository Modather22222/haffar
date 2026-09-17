import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles authentication — anonymous sign-in as the default identity.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  bool get isSignedIn => _client.auth.currentSession != null;

  /// Restore the existing session or sign in anonymously.
  /// Returns false when remote identity is unavailable (local-only mode).
  Future<bool> ensureSignedIn() async {
    if (isSignedIn) return true;
    try {
      await _client.auth.signInAnonymously();
      return true;
    } catch (_) {
      return false;
    }
  }
}
