import 'package:flutter/material.dart';

import '../models/idea_variant.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/keyword_tag.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/mode_badge.dart';
import 'idea_detail_screen.dart';

class IdeasListScreen extends StatefulWidget {
  final List<IdeaVariant> variants;
  final String productText;
  final String? productURL;
  final String? sessionId;
  final bool random;

  const IdeasListScreen({
    super.key,
    required this.variants,
    required this.productText,
    this.productURL,
    this.sessionId,
    this.random = false,
  });

  @override
  State<IdeasListScreen> createState() => _IdeasListScreenState();
}

class _IdeasListScreenState extends State<IdeasListScreen> {
  late List<IdeaVariant> _variants;
  bool _isLoading = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _variants = widget.variants;
    _sessionId = widget.sessionId;
  }

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final newVariants = await ApiClient.instance.generateIdeas(
        text: widget.random ? '' : widget.productText,
        random: widget.random,
      );

      // Update session with new variants (fire and forget)
      if (_sessionId != null) {
        ApiClient.instance.updateSession(_sessionId!, {
          'variants_json': newVariants.map((v) => v.toJson()).toList(),
          'status': 'ideas_generated',
        }).catchError((_) {});
      }

      if (mounted) {
        setState(() => _variants = newVariants);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Ideas'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryAmber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Generate new ideas',
              color: AppColors.primaryAmber,
              onPressed: _isLoading ? null : _regenerate,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Subtle gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.warmWhite, Color(0xFFFFF9F0)],
              ),
            ),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl,
            ),
            itemCount: _variants.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.base,
                    top: AppSpacing.sm,
                    left: AppSpacing.xs,
                  ),
                  child: Text(
                    '${_variants.length} hero ideas generated',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.mutedGray,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                );
              }
              final variant = _variants[index - 1];
              return _VariantTile(
                variant: variant,
                index: index,
                onTap: () {
                  // Save selected variant (fire and forget)
                  if (_sessionId != null) {
                    ApiClient.instance.updateSession(_sessionId!, {
                      'selected_variant_json': variant.toJson(),
                      'title': variant.title,
                    }).catchError((_) {});
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => IdeaDetailScreen(
                        variant: variant,
                        productText: widget.productText,
                        productURL: widget.productURL,
                        sessionId: _sessionId,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            const LoadingOverlay(message: 'Finding fresh hero ideas...'),
        ],
      ),
    );
  }
}

class _VariantTile extends StatelessWidget {
  final IdeaVariant variant;
  final int index;
  final VoidCallback onTap;

  const _VariantTile({
    required this.variant,
    required this.index,
    required this.onTap,
  });

  Color get _accentColor {
    switch (variant.improvementMode) {
      case 'cost_down':
        return const Color(0xFF2196F3);
      case 'durability':
        return const Color(0xFF795548);
      case 'safety':
        return const Color(0xFFE53935);
      case 'convenience':
        return const Color(0xFF43A047);
      case 'sustainability':
        return const Color(0xFF00897B);
      case 'performance':
        return const Color(0xFFEF6C00);
      case 'mashup':
        return const Color(0xFF7B1FA2);
      default:
        return AppColors.warmGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.lightWarmGray.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Row(
                children: [
                  // Colored accent bar
                  Container(
                    width: 5,
                    height: 130,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _accentColor,
                          _accentColor.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.base),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number + badge row
                          Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: _accentColor.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Center(
                                  child: Text(
                                    '$index',
                                    style: TextStyle(
                                      color: _accentColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  variant.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.darkCharcoal,
                                        letterSpacing: -0.2,
                                      ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              ModeBadge(
                                mode: variant.improvementMode,
                                label: variant.modeLabel,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Summary
                          Padding(
                            padding: const EdgeInsets.only(left: 34),
                            child: Text(
                              variant.summary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.mutedGray,
                                    height: 1.4,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Keywords
                          Padding(
                            padding: const EdgeInsets.only(left: 34),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: variant.keywords
                                  .take(4)
                                  .map((k) => KeywordTag(text: k))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.lightWarmGray,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
