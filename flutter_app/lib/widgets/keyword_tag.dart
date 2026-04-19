import 'package:flutter/material.dart';

import '../theme.dart';

class KeywordTag extends StatelessWidget {
  final String text;
  const KeywordTag({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: fontMono,
          color: AppColors.accentInk,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
