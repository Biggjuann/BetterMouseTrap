import 'package:flutter/material.dart';

import '../theme.dart';

class KeywordTag extends StatelessWidget {
  final String text;
  const KeywordTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.softCream,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.lightWarmGray.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.richBrown,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
