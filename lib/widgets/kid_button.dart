import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

enum KidButtonVariant { primary, secondary, accent, ghost }

class KidButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final KidButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KidButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<KidButton> createState() => _KidButtonState();
}

class _KidButtonState extends State<KidButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.variant) {
      case KidButtonVariant.primary:
        return AppColors.primary;
      case KidButtonVariant.secondary:
        return AppColors.secondary;
      case KidButtonVariant.accent:
        return AppColors.accent;
      case KidButtonVariant.ghost:
        return Colors.transparent;
    }
  }

  Color get _fgColor {
    switch (widget.variant) {
      case KidButtonVariant.primary:
        return AppColors.primaryForeground;
      case KidButtonVariant.secondary:
        return AppColors.secondaryForeground;
      case KidButtonVariant.accent:
        return AppColors.accentForeground;
      case KidButtonVariant.ghost:
        return AppColors.primary;
    }
  }

  Border? get _border {
    if (widget.variant == KidButtonVariant.ghost) {
      return Border.all(color: AppColors.primary, width: 2);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(32),
            border: _border,
            boxShadow: widget.variant != KidButtonVariant.ghost
                ? [
                    BoxShadow(
                      color: _bgColor.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: _fgColor, size: 22),
                const SizedBox(width: 10),
              ],
              if (widget.isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: _fgColor,
                    strokeWidth: 2,
                  ),
                )
              else
                Text(
                  widget.label,
                  style: TextStyle(
                    color: _fgColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
