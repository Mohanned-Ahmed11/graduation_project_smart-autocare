import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/auth_redirect.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: AuthRedirect.callback,
    );
  }

  /// Requires Google / Facebook providers enabled in Supabase and this redirect URL whitelisted.
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: AuthRedirect.callback,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }
}
