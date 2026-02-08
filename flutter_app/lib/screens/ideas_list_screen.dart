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
      appBar: AppBar(
        title: const Text('Your Ideas'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Generate new ideas',
              onPressed: _isLoading ? null : _regenerate,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xl,
            ),
            itemCount: _variants.length + 1,
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
        return const Color(0xFFD93025);
      case 'convenience':
        return const Color(0xFF2E7D44);
      case 'sustainability':
        return const Color(0xFF1A8A8A);
      case 'performance':
        return const Color(0xFFD48500);
      case 'mashup':
        return const Color(0xFF7B1FA2);
      default:
        return AppColors.stone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.card,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Row(
                children: [
                  // Colored accent bar
                  Container(
                    width: 4,
                    height: 130,
                    color: _accentColor,
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
                                  ?.copyWith(height: 1.4),
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
                      color: Theme.of(context).colorScheme.outline,
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
