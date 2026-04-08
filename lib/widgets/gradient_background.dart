import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum GradientVariant { main, purple, mint }

class GradientBackground extends StatelessWidget {
  final Widget child;
  final GradientVariant variant;

  const GradientBackground({
    super.key,
    required this.child,
    this.variant = GradientVariant.main,
  });

  LinearGradient _gradient() {
    switch (variant) {
      case GradientVariant.purple:
        return AppColors.purpleGradient();
      case GradientVariant.mint:
        return AppColors.mintGradient();
      case GradientVariant.main:
      // ignore: unreachable_switch_default
      default:
        return AppColors.mainGradient();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _gradient()),
      child: child,
    );
  }
}
