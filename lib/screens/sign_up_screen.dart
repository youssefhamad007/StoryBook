import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kid_button.dart';

/// The Sign Up screen — name, email, password with strength indicator,
/// confirm password, Google OAuth, and navigation to Sign In.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ── Validation ──────────────────────────────────────────────────────────

  bool _validateFields() {
    bool valid = true;

    final nameErr = AuthProvider.validateName(_nameController.text);
    if (nameErr != null) {
      _nameError = nameErr;
      valid = false;
    } else {
      _nameError = null;
    }

    final emailErr = AuthProvider.validateEmail(_emailController.text);
    if (emailErr != null) {
      _emailError = emailErr;
      valid = false;
    } else {
      _emailError = null;
    }

    final passErr = AuthProvider.validatePassword(_passwordController.text);
    if (passErr != null) {
      _passwordError = passErr;
      valid = false;
    } else {
      _passwordError = null;
    }

    final confErr = AuthProvider.validateConfirmPassword(
      _passwordController.text,
      _confirmController.text,
    );
    if (confErr != null) {
      _confirmError = confErr;
      valid = false;
    } else {
      _confirmError = null;
    }

    setState(() {});
    return valid;
  }

  // ── Sign Up ─────────────────────────────────────────────────────────────

  Future<void> _handleSignUp() async {
    if (!_validateFields()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.signUpWithEmail(
      _nameController.text,
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
  }

  // ── Password strength ───────────────────────────────────────────────────

  Widget _buildPasswordStrengthBar() {
    final strength = AuthProvider.passwordStrength(_passwordController.text);
    if (_passwordController.text.isEmpty) return const SizedBox.shrink();

    const labels = ['', 'Weak', 'Medium', 'Strong'];
    const colors = [
      Colors.transparent,
      Color(0xFFFF6B6B),
      Color(0xFFFFAA33),
      Color(0xFF51CF66),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strength bars
          Row(
            children: List.generate(3, (i) {
              final isActive = i < strength;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: isActive
                        ? colors[strength]
                        : AppColors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            labels[strength],
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors[strength],
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: GradientBackground(
        variant: GradientVariant.main,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset * 0.3),
            child: Column(
              children: [
                const SizedBox(height: 6),

                // ── App branding ──────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
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
                    child: Text('📚', style: TextStyle(fontSize: 42)),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 16),

                const Text(
                  'Join StoryBook!',
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
                  'Create your storytelling account',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

                const SizedBox(height: 28),

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

                // ── Full Name field ───────────────────────────────────
                AuthTextField(
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.accent,
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 14),

                // ── Email field ───────────────────────────────────────
                AuthTextField(
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ).animate().fadeIn(delay: 370.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 14),

                // ── Password field + strength ─────────────────────────
                AuthTextField(
                  label: 'Password',
                  hint: 'Create a strong password',
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.gradientPurple,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  errorText: _passwordError,
                  onChanged: (_) {
                    setState(() {
                      if (_passwordError != null) _passwordError = null;
                    });
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
                ).animate().fadeIn(delay: 440.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                _buildPasswordStrengthBar(),

                const SizedBox(height: 14),

                // ── Confirm Password field ────────────────────────────
                AuthTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  icon: Icons.lock_person_outlined,
                  iconColor: AppColors.gradientMint,
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  errorText: _confirmError,
                  onChanged: (_) {
                    if (_confirmError != null) {
                      setState(() => _confirmError = null);
                    }
                  },
                  suffixWidget: GestureDetector(
                    onTap: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    child: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.mutedForeground,
                      size: 20,
                    ),
                  ),
                ).animate().fadeIn(delay: 510.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 24),

                // ── Create Account button ─────────────────────────────
                KidButton(
                  label: 'Create Account',
                  icon: Icons.person_add_alt_1_rounded,
                  isLoading: authProvider.isLoading,
                  onPressed: _handleSignUp,
                ).animate().fadeIn(delay: 580.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 22),

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
                ).animate().fadeIn(delay: 640.ms),

                const SizedBox(height: 22),

                // ── Google button ─────────────────────────────────────
                GoogleSignInButton(
                  isLoading: authProvider.isLoading,
                  onPressed: _handleGoogleSignIn,
                ).animate().fadeIn(delay: 700.ms, duration: 400.ms).slideY(
                      begin: 0.2,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 28),

                // ── Footer link ───────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.mutedForeground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacementNamed(
                          context, '/sign-in'),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 760.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
