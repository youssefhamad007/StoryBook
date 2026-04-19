import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

/// Manages authentication state for the Storybook app.
///
/// Wraps [SupabaseAuthService] and exposes reactive state via
/// [ChangeNotifier] for the Provider pattern used throughout the project.
class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();

  // ── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  String? _errorMessage;
  User? _user;
  StreamSubscription<AuthState>? _authSubscription;

  // ── Getters ────────────────────────────────────────────────────────────
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  // ── Constructor ────────────────────────────────────────────────────────

  AuthProvider() {
    _listenToAuthChanges();
  }

  /// Listens to Supabase auth state changes and updates the local user.
  void _listenToAuthChanges() {
    _authSubscription = _authService.authStateChanges.listen((authState) {
      final session = authState.session;
      _user = session?.user;
      notifyListeners();

      log(
        'Auth state changed: ${authState.event.name} | '
        'user=${_user?.email ?? "null"}',
        name: 'AuthProvider',
      );
    });
  }

  // ── Check Auth State (on app start) ────────────────────────────────────

  /// Checks if a user session already exists (e.g., after app restart).
  void checkAuthState() {
    _user = _authService.getCurrentUser();
    notifyListeners();
  }

  // ── Sign In with Email ─────────────────────────────────────────────────

  /// Validates inputs then signs in with email/password via Supabase.
  ///
  /// Returns `true` on success, `false` on failure (error stored in
  /// [errorMessage]).
  Future<bool> signInWithEmail(String email, String password) async {
    // Client-side validation
    final emailError = validateEmail(email);
    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }
    if (password.isEmpty) {
      _errorMessage = 'Please enter your password';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmail(email.trim(), password);
      _user = _authService.getCurrentUser();
      _setLoading(false);
      return true;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Up with Email ─────────────────────────────────────────────────

  /// Validates inputs then creates a new account via Supabase.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password,
  ) async {
    // Client-side validation
    final nameError = validateName(name);
    if (nameError != null) {
      _errorMessage = nameError;
      notifyListeners();
      return false;
    }
    final emailError = validateEmail(email);
    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _authService.signUpWithEmail(email.trim(), password);
      _user = _authService.getCurrentUser();
      _setLoading(false);
      return true;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Google Sign In ─────────────────────────────────────────────────────

  /// Triggers Google OAuth flow via Supabase.
  ///
  /// Returns `true` if the OAuth flow was initiated successfully.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.signInWithGoogle();
      _setLoading(false);
      return success;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Google sign-in failed. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────

  /// Sends a password reset email via Supabase.
  ///
  /// Returns `true` if the email was sent successfully.
  Future<bool> resetPassword(String email) async {
    final emailError = validateEmail(email);
    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await Supabase.instance.client.auth
          .resetPasswordForEmail(email.trim());
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = 'Password reset failed: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────

  /// Signs out the current user and clears local state.
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _user = null;
    } on AuthServiceException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Sign-out failed. Please try again.';
    }

    _setLoading(false);
  }

  // ── Error Management ───────────────────────────────────────────────────

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Validation Helpers (static, reusable) ──────────────────────────────

  /// Returns an error string if [name] is invalid, or `null` if valid.
  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Please enter your name';
    if (name.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  /// Returns an error string if [email] is invalid, or `null` if valid.
  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'Please enter your email';
    final regex = RegExp(r'^[\w\.\-\+]+@[\w\-]+\.\w{2,}$');
    if (!regex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Returns an error string if [password] is invalid, or `null` if valid.
  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Returns an error string if [confirm] doesn't match [password].
  static String? validateConfirmPassword(String password, String confirm) {
    if (confirm.isEmpty) return 'Please confirm your password';
    if (password != confirm) return 'Passwords do not match';
    return null;
  }

  /// Returns a password strength level (0–3) for UI indicator.
  /// 0 = empty, 1 = weak, 2 = medium, 3 = strong
  static int passwordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[a-zA-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password)) {
      score++;
    }
    if (password.length >= 12 &&
        RegExp(r'[!@#\$%\^&\*\(\)_\+\-=\[\]\{\};:,\.<>\?]')
            .hasMatch(password)) {
      score++;
    }
    return score;
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
