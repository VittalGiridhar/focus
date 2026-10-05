import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A glowing ring with an icon, used for headers, empty and success states.
class GlowRing extends StatelessWidget {
  const GlowRing({super.key, required this.icon, this.size = 88, this.color = AppColors.accent});

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.08),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 32)],
        ),
        child: Icon(icon, color: color, size: size * 0.42),
      ),
    );
  }
}
