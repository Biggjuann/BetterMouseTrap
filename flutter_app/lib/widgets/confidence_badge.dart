import 'package:flutter/material.dart';

import '../theme.dart';

class ConfidenceBadge extends StatelessWidget {
  final String level;
  const ConfidenceBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (level) {
      case 'high':
        return 'High';
      case 'med':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  Color get _color {
    switch (level) {
      case 'high':
        return AppColors.successGreen;
      case 'med':
        return AppColors.heroOrange;
      default:
        return const Color(0xFFE53935);
    }
  }

  IconData get _icon {
    switch (level) {
      case 'high':
        return Icons.verified;
      case 'med':
        return Icons.info_outline;
      default:
        return Icons.warning_amber;
    }
  }
}
