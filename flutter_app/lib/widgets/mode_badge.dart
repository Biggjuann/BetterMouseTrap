import 'package:flutter/material.dart';

import '../theme.dart';

class ModeBadge extends StatelessWidget {
  final String mode;
  final String label;
  const ModeBadge({super.key, required this.mode, required this.label});

  @override
  Widget build(BuildContext context) {
    final config = _configForMode(mode);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: config.gradientColors,
        ),
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: config.gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  static _ModeConfig _configForMode(String mode) {
    switch (mode) {
      case 'cost_down':
        return _ModeConfig(
          gradientColors: [const Color(0xFF2196F3), const Color(0xFF42A5F5)],
          icon: Icons.savings,
        );
      case 'durability':
        return _ModeConfig(
          gradientColors: [const Color(0xFF795548), const Color(0xFF8D6E63)],
          icon: Icons.shield,
        );
      case 'safety':
        return _ModeConfig(
          gradientColors: [const Color(0xFFE53935), const Color(0xFFEF5350)],
          icon: Icons.health_and_safety,
        );
      case 'convenience':
        return _ModeConfig(
          gradientColors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
          icon: Icons.touch_app,
        );
      case 'sustainability':
        return _ModeConfig(
          gradientColors: [const Color(0xFF00897B), const Color(0xFF26A69A)],
          icon: Icons.eco,
        );
      case 'performance':
        return _ModeConfig(
          gradientColors: [const Color(0xFFEF6C00), const Color(0xFFFB8C00)],
          icon: Icons.speed,
        );
      case 'mashup':
        return _ModeConfig(
          gradientColors: [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)],
          icon: Icons.merge_type,
        );
      default:
        return _ModeConfig(
          gradientColors: [AppColors.warmGray, AppColors.mutedGray],
          icon: Icons.lightbulb_outline,
        );
    }
  }
}

class _ModeConfig {
  final List<Color> gradientColors;
  final IconData icon;
  const _ModeConfig({required this.gradientColors, required this.icon});
}
