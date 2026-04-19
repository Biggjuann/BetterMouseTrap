import 'package:flutter/material.dart';

import '../theme.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border(left: BorderSide(color: AppColors.accentInk, width: 2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.accentInk, size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A drafting aid — not legal advice. Review with a patent attorney before filing.',
              style: AppText.caption.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.graphite,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
