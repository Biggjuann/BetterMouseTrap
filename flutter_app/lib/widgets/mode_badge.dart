import 'package:flutter/material.dart';

import '../theme.dart';

// Editorial Studio: mode badges now use accent-soft wash + ink label
// with a mono caps treatment. Icon disambiguates.

class ModeBadge extends StatelessWidget {
  final String mode;
  final String label;
  const ModeBadge({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForMode(mode), size: 11, color: AppColors.accentInk),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: fontMono,
              color: AppColors.accentInk,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForMode(String mode) {
    switch (mode) {
      case 'cost_down': return Icons.savings_outlined;
      case 'durability': return Icons.shield_outlined;
      case 'safety': return Icons.health_and_safety_outlined;
      case 'convenience': return Icons.touch_app_outlined;
      case 'sustainability': return Icons.eco_outlined;
      case 'performance': return Icons.speed_rounded;
      case 'mashup': return Icons.merge_type_rounded;
      default: return Icons.lightbulb_outline;
    }
  }
}
