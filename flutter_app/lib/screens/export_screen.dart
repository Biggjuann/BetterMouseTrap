import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/api_responses.dart';
import '../theme.dart';
import '../widgets/disclaimer_banner.dart';

class ExportScreen extends StatelessWidget {
  final ExportResponse exportResponse;
  const ExportScreen({super.key, required this.exportResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your One-Pager'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy to clipboard',
              color: AppColors.primaryAmber,
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: exportResponse.plainText),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.warmWhite, Color(0xFFFFF9F0)],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.lightWarmGray.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: exportResponse.markdown,
                    selectable: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                const DisclaimerBanner(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
