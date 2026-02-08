import 'package:flutter/material.dart';

import '../theme.dart';

class ScoreBadge extends StatelessWidget {
  final double score;
  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              color: _color.withValues(alpha: 0.12),
            ),
          ),
          // Score ring
          SizedBox(
            width: 48,
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score),
              duration: AppDuration.slow,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                color: _color,
              ),
            ),
          ),
          // Center text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _color,
                  height: 1,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '%',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _color.withValues(alpha: 0.7),
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _color {
    if (score >= 0.7) return const Color(0xFFE53935);
    if (score >= 0.4) return AppColors.heroOrange;
    return AppColors.successGreen;
  }
}

/// A compact inline score indicator (used in list tiles)
class ScoreIndicator extends StatelessWidget {
  final double score;
  const ScoreIndicator({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          color: _color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Color get _color {
    if (score >= 0.7) return const Color(0xFFE53935);
    if (score >= 0.4) return AppColors.heroOrange;
    return AppColors.successGreen;
  }
}
