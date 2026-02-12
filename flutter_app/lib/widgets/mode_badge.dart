import 'package:flutter/material.dart';

import '../theme.dart';

class ModeBadge extends StatelessWidget {
  final String mode;
  final String label;
  const ModeBadge({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForMode(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.$1.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.$1.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForMode(mode), size: 12, color: colors.$1),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.$1,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static (Color,) _colorsForMode(String mode) {
    switch (mode) {
      case 'cost_down':
        return (AppColors.blueText,);
      case 'durability':
        return (const Color(0xFF795548),);
      case 'safety':
        return (AppColors.error,);
      case 'convenience':
        return (AppColors.emeraldText,);
      case 'sustainability':
        return (AppColors.teal,);
      case 'performance':
        return (AppColors.primary,);
      case 'mashup':
        return (AppColors.purpleText,);
      default:
        return (AppColors.stone,);
    }
  }

  static IconData _iconForMode(String mode) {
    switch (mode) {
      case 'cost_down':
        return Icons.savings_outlined;
      case 'durability':
        return Icons.shield_outlined;
      case 'safety':
        return Icons.health_and_safety_outlined;
      case 'convenience':
        return Icons.touch_app_outlined;
      case 'sustainability':
        return Icons.eco_outlined;
      case 'performance':
        return Icons.speed;
      case 'mashup':
        return Icons.merge_type;
      default:
        return Icons.lightbulb_outline;
    }
  }
}
