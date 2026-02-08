import 'package:flutter/material.dart';

import '../theme.dart';

class ModeBadge extends StatelessWidget {
  final String mode;
  final String label;
  const ModeBadge({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _colorForMode(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconForMode(mode), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  static Color _colorForMode(String mode) {
    switch (mode) {
      case 'cost_down':
        return const Color(0xFF2196F3);
      case 'durability':
        return const Color(0xFF795548);
      case 'safety':
        return const Color(0xFFD93025);
      case 'convenience':
        return const Color(0xFF2E7D44);
      case 'sustainability':
        return const Color(0xFF1A8A8A);
      case 'performance':
        return const Color(0xFFD48500);
      case 'mashup':
        return const Color(0xFF7B1FA2);
      default:
        return AppColors.stone;
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
