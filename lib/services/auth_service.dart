import 'dart:developer';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A dedicated service class that acts as the bridge between
/// the Flutter app and Supabase Authentication.
///
/// Usage:
/// ```dart
/// final authService = SupabaseAuthService();
/// await authService.signInWithEmail('user@example.com', 'password123');
/// ```
///
/// This class assumes [Supabase.initialize] has already been called
/// (typically in `main.dart`) before any method is invoked.
class SupabaseAuthService {
  /// Direct reference to the Supabase auth client.
  final GoTrueClient _auth = Supabase.instance.client.auth;

  // ---------------------------------------------------------------------------
  // Auth State Stream
  // ---------------------------------------------------------------------------

  /// A broadcast stream that emits [AuthState] events whenever the user's
  /// authentication status changes (sign-in, sign-out, token refresh, etc.).
  ///
  /// The UI layer (e.g., an AuthProvider) can listen to this stream to
  /// reactively update navigation and user state.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Current User
  // ---------------------------------------------------------------------------

  /// Returns the currently authenticated [User], or `null` if no session
  /// is active.
  User? getCurrentUser() => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // Email / Password — Sign Up
  // ---------------------------------------------------------------------------

  /// Registers a new user with [email] and [password].
  ///
  /// On success, Supabase will also fire the database trigger that
  /// auto-creates the user's `profiles` row.
  ///
  /// Throws [AuthServiceException] on failure.
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      log('SignUp failed: ${e.message}', name: 'SupabaseAuthService');
      throw AuthServiceException('Sign-up failed: ${e.message}');
    } catch (e) {
      log('SignUp unexpected error: $e', name: 'SupabaseAuthService');
      throw AuthServiceException(
        'An unexpected error occurred during sign-up. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Email / Password — Sign In
  // ---------------------------------------------------------------------------

  /// Authenticates an existing user with [email] and [password].
  ///
  /// Returns an [AuthResponse] containing the session and user data.
  ///
  /// Throws [AuthServiceException] on failure.
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      log('SignIn failed: ${e.message}', name: 'SupabaseAuthService');
      throw AuthServiceException('Sign-in failed: ${e.message}');
    } catch (e) {
      log('SignIn unexpected error: $e', name: 'SupabaseAuthService');
      throw AuthServiceException(
        'An unexpected error occurred during sign-in. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Google OAuth — Sign In
  // ---------------------------------------------------------------------------

  /// Initiates the Google OAuth sign-in flow.
  ///
  /// This opens the device's browser / in-app web view for the user to
  /// authenticate with their Google account. On success, the Supabase
  /// auth state stream will emit a `signedIn` event.
  ///
  /// Throws [AuthServiceException] on failure.
  Future<bool> signInWithGoogle() async {
    try {
      final success = await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.storybook://login-callback/',
      );
      return success;
    } on AuthException catch (e) {
      log('Google sign-in failed: ${e.message}', name: 'SupabaseAuthService');
      throw AuthServiceException('Google sign-in failed: ${e.message}');
    } catch (e) {
      log('Google sign-in unexpected error: $e', name: 'SupabaseAuthService');
      throw AuthServiceException(
        'An unexpected error occurred during Google sign-in. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign Out
  // ---------------------------------------------------------------------------

  /// Signs the current user out and clears the local session.
  ///
  /// Throws [AuthServiceException] on failure.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on AuthException catch (e) {
      log('SignOut failed: ${e.message}', name: 'SupabaseAuthService');
      throw AuthServiceException('Sign-out failed: ${e.message}');
    } catch (e) {
      log('SignOut unexpected error: $e', name: 'SupabaseAuthService');
      throw AuthServiceException(
        'An unexpected error occurred during sign-out. Please try again.',
      );
    }
  }
}

// -----------------------------------------------------------------------------
// Custom Exception
// -----------------------------------------------------------------------------

/// A clean, user-facing exception type for authentication errors.
///
/// The [message] is safe to display in the UI (e.g., in a SnackBar).
class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() => 'AuthServiceException: $message';
}
