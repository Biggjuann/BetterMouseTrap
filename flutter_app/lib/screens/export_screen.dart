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
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: 'Copy to clipboard',
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: exportResponse.plainText),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Document card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: MarkdownBody(
                    data: exportResponse.markdown,
                    selectable: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
