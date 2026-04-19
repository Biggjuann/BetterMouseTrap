import 'package:flutter/material.dart';

import '../theme.dart';

// Editorial Studio: score rendered as a thin ring with a tabular
// number inside. Color uses accent ink for low risk, sun for medium,
// warm for high — all tonal, never saturated primaries.

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
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 2,
              color: AppColors.hairline,
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score),
              duration: AppDuration.slow,
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 2,
                strokeCap: StrokeCap.round,
                color: _color,
              ),
            ),
          ),
          Text(
            '$pct',
            style: TextStyle(
              fontFamily: fontDisplay,
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
              height: 1,
              letterSpacing: -0.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    if (score >= 0.7) return AppColors.warm;
    if (score >= 0.4) return AppColors.sun;
    return AppColors.accentInk;
  }
}

class ScoreIndicator extends StatelessWidget {
  final double score;
  const ScoreIndicator({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Text(
        '$pct%',
        style: TextStyle(
          fontFamily: fontMono,
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Color get _color {
    if (score >= 0.7) return AppColors.warm;
    if (score >= 0.4) return AppColors.sun;
    return AppColors.accentInk;
  }
}
