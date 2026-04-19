import 'package:flutter/material.dart';

import '../theme.dart';

// Editorial Studio: confidence rendered as mono caps inside an
// accent-soft (for high), canvas (for med), or warm (for low) wash.

class ConfidenceBadge extends StatelessWidget {
  final String level;
  const ConfidenceBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 11, color: fg),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontFamily: fontMono,
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    switch (level) {
      case 'high': return 'CLEAR';
      case 'med': return 'REVIEW';
      default: return 'CROWDED';
    }
  }

  (Color, Color) get _tone {
    switch (level) {
      case 'high': return (AppColors.accentSoft, AppColors.accentInk);
      case 'med':  return (AppColors.sunSoft, AppColors.ink);
      default:     return (AppColors.warmSoft, AppColors.warm);
    }
  }

  IconData get _icon {
    switch (level) {
      case 'high': return Icons.check_rounded;
      case 'med':  return Icons.remove_rounded;
      default:     return Icons.warning_amber_rounded;
    }
  }
}
