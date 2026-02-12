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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          Column(
            children: [
              // Stitch nav bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.05),
                              ),
                              boxShadow: AppShadows.card,
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'ONE-PAGER',
                                style: TextStyle(
                                  color: AppColors.primary.withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Text(
                                'Invention Summary',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.05),
                              ),
                              boxShadow: AppShadows.card,
                            ),
                            child: const Icon(
                              Icons.share,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
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
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document card — Stitch style
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.05),
                          ),
                          boxShadow: AppShadows.elevated,
                        ),
                        child: MarkdownBody(
                          data: exportResponse.markdown,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            h1: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              height: 1.3,
                            ),
                            h2: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                            h3: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                              height: 1.4,
                            ),
                            p: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.ink,
                              height: 1.6,
                            ),
                            strong: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            em: const TextStyle(
                              fontFamily: 'Manrope',
                              fontStyle: FontStyle.italic,
                              color: AppColors.ink,
                            ),
                            listBullet: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.only(
                              left: AppSpacing.md,
                              top: AppSpacing.sm,
                              bottom: AppSpacing.sm,
                            ),
                            horizontalRuleDecoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            h1Padding: const EdgeInsets.only(
                              top: AppSpacing.sm,
                              bottom: AppSpacing.md,
                            ),
                            h2Padding: const EdgeInsets.only(
                              top: AppSpacing.lg,
                              bottom: AppSpacing.sm,
                            ),
                            h3Padding: const EdgeInsets.only(
                              top: AppSpacing.md,
                              bottom: AppSpacing.xs,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      const DisclaimerBanner(),

                      // Extra bottom padding for the fixed footer
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed bottom action bar — Stitch
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: AppShadows.button,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: FilledButton(
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Copy to Clipboard'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
