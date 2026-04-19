import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/gradient_background.dart';
import '../widgets/kid_button.dart';

/// Forgot Password screen — enter email to receive a password reset link.
/// Shows a success state after the email is sent.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String? _emailError;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ── Send reset email ────────────────────────────────────────────────────

  Future<void> _handleResetPassword() async {
    final emailError = AuthProvider.validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _emailError = emailError);
      return;
    }
    setState(() => _emailError = null);

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success = await authProvider.resetPassword(_emailController.text);
    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: GradientBackground(
        variant: GradientVariant.mint,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header bar ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.foreground),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Reset Password',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.foreground,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40), // Spacer for centering
                  ],
                ),
              ),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                  child: _emailSent
                      ? _buildSuccessState()
                      : _buildFormState(authProvider),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form state (before sending) ─────────────────────────────────────────

  Widget _buildFormState(AuthProvider authProvider) {
    return Column(
      children: [
        // Icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('🔑', style: TextStyle(fontSize: 48)),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
              duration: 500.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 24),

        const Text(
          'Forgot Your Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.foreground,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(
              begin: 0.3,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 8),

        const Text(
          "No worries! Enter your email and we'll\nsend you a password reset link.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 250.ms, duration: 400.ms),

        const SizedBox(height: 36),

        // ── Error banner ──────────────────────────────────────────
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
          ).animate().fadeIn(duration: 300.ms),

        // ── Email field ───────────────────────────────────────────
        AuthTextField(
          label: 'Email Address',
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          iconColor: AppColors.accent,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(
              begin: 0.2,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 28),

        // ── Send button ───────────────────────────────────────────
        KidButton(
          label: 'Send Reset Link',
          icon: Icons.send_rounded,
          isLoading: authProvider.isLoading,
          variant: KidButtonVariant.accent,
          onPressed: _handleResetPassword,
        ).animate().fadeIn(delay: 380.ms, duration: 400.ms).slideY(
              begin: 0.2,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 28),

        // ── Back to sign in link ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Remember your password? ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.mutedForeground,
                fontWeight: FontWeight.w500,
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(context),
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
        ).animate().fadeIn(delay: 440.ms),
      ],
    );
  }

  // ── Success state (after sending) ───────────────────────────────────────

  Widget _buildSuccessState() {
    return Column(
      children: [
        const SizedBox(height: 40),

        // Success icon
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF51CF66).withValues(alpha: 0.3),
                blurRadius: 24,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('✅', style: TextStyle(fontSize: 52)),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),

        const SizedBox(height: 28),

        const Text(
          'Check Your Email!',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.foreground,
            letterSpacing: -0.3,
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(
              begin: 0.3,
              curve: Curves.easeOut,
            ),

        const SizedBox(height: 10),

        Text(
          'We sent a password reset link to\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 350.ms, duration: 400.ms),

        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8FFF0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: Color(0xFF2B8A3E)),
              SizedBox(width: 8),
              Text(
                "Don't forget to check your spam folder",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B8A3E),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

        const SizedBox(height: 40),

        // Back to Sign In button
        KidButton(
          label: 'Back to Sign In',
          icon: Icons.arrow_back_rounded,
          variant: KidButtonVariant.ghost,
          onPressed: () => Navigator.pop(context),
        ).animate().fadeIn(delay: 600.ms, duration: 400.ms).slideY(
              begin: 0.2,
              curve: Curves.easeOut,
            ),
      ],
    );
  }
}
