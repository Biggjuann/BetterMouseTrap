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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          CustomScrollView(
            slivers: [
              // Header — Stitch style
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                              color: AppColors.primary,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              'PREMIUM ACCESS',
                              style: TextStyle(
                                color: AppColors.primary.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            // Avatar placeholder
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                color: AppColors.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.person,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.base),

                        // Title
                        Text(
                          'Invention Ideas',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),

                        // Search bar — Stitch
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.cardWhite,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                  boxShadow: AppShadows.card,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    Icon(Icons.search, color: AppColors.slateLight, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Search concepts...',
                                      style: TextStyle(
                                        color: AppColors.slateLight,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                boxShadow: AppShadows.card,
                              ),
                              child: Icon(Icons.tune, color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),

              // Idea cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final variant = _variants[index];
                      return _VariantCard(
                        variant: variant,
                        onTap: () {
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
                    childCount: _variants.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // FAB — Stitch: "Generate New Ideas"
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: AppShadows.button,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: FilledButton(
                  onPressed: _isLoading ? null : _regenerate,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.base,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Generate New Ideas'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const LoadingOverlay(message: 'Finding fresh hero ideas...'),
        ],
      ),
    );
  }
}

// Stitch-style idea card
class _VariantCard extends StatelessWidget {
  final IdeaVariant variant;
  final VoidCallback onTap;

  const _VariantCard({
    required this.variant,
    required this.onTap,
  });

  IconData get _modeIcon {
    switch (variant.improvementMode) {
      case 'cost_down':
        return Icons.savings_outlined;
      case 'durability':
        return Icons.shield_outlined;
      case 'safety':
        return Icons.health_and_safety_outlined;
      case 'convenience':
        return Icons.touch_app_outlined;
      case 'sustainability':
        return Icons.eco_outlined;
      case 'performance':
        return Icons.speed;
      case 'mashup':
        return Icons.merge_type;
      default:
        return Icons.lightbulb_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box — Stitch
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(_modeIcon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: AppSpacing.base),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              variant.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.slateLight,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        variant.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.stone,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Badge row — Stitch style
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ModeBadge(
                            mode: variant.improvementMode,
                            label: variant.modeLabel,
                          ),
                          ...variant.keywords
                              .take(2)
                              .map((k) => KeywordTag(text: k)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
