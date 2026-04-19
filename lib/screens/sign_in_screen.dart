import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kid_button.dart';

/// The Sign In screen — email/password login, Google OAuth, and
/// navigation to Sign Up and Forgot Password.
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  bool _validateFields() {
    bool valid = true;

    final emailError = AuthProvider.validateEmail(_emailController.text);
    if (emailError != null) {
      _emailError = emailError;
      valid = false;
    } else {
      _emailError = null;
    }

    if (_passwordController.text.isEmpty) {
      _passwordError = 'Please enter your password';
      valid = false;
    } else {
      _passwordError = null;
    }

    setState(() {});
    return valid;
  }

  // ── Sign In ─────────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    if (!_validateFields()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signInWithEmail(
      _emailController.text,
      _passwordController.text,
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    await authProvider.signInWithGoogle();
    // Navigation is handled by auth state listener in splash/main
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: GradientBackground(
        variant: GradientVariant.purple,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset * 0.3),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // ── App branding ──────────────────────────────────────
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('📚', style: TextStyle(fontSize: 48)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 20),

                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.foreground,
                    letterSpacing: -0.3,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(
                      begin: 0.3,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 6),

                const Text(
                  'Sign in to continue your stories',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                const SizedBox(height: 32),

                // ── Error banner ──────────────────────────────────────
                if (authProvider.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: AppColors.destructive, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            authProvider.errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.destructive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).shake(
                        hz: 3,
                        offset: const Offset(2, 0),
                        duration: 400.ms,
                      ),

                // ── Email field ───────────────────────────────────────
                AuthTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) {
                      setState(() => _emailError = null);
                    }
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 16),

                // ── Password field ────────────────────────────────────
                AuthTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  errorText: _passwordError,
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  suffixWidget: GestureDetector(
                    onTap: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.mutedForeground,
                      size: 20,
                    ),
                  ),
                ).animate().fadeIn(delay: 380.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                // ── Forgot password link ──────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10, right: 4),
                    child: GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/forgot-password'),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 440.ms),

                const SizedBox(height: 24),

                // ── Sign in button ────────────────────────────────────
                KidButton(
                  label: 'Sign In',
                  icon: Icons.login_rounded,
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSignIn,
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                          height: 1.5,
                          color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                          height: 1.5,
                          color: AppColors.border.withValues(alpha: 0.6)),
                    ),
                  ],
                ).animate().fadeIn(delay: 560.ms),

                const SizedBox(height: 24),

                // ── Google button ─────────────────────────────────────
                GoogleSignInButton(
                  isLoading: authProvider.isLoading,
                  onPressed: _handleGoogleSignIn,
                ).animate().fadeIn(delay: 620.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),

                // ── Footer link ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/sign-up'),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 680.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
