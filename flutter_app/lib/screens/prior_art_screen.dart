import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/score_badge.dart';
import 'build_this_screen.dart';
import 'export_screen.dart';

class PriorArtScreen extends StatefulWidget {
  final ProductInput product;
  final IdeaVariant variant;
  final IdeaSpec spec;
  final PatentSearchResponse patentResponse;
  final String? sessionId;

  const PriorArtScreen({
    super.key,
    required this.product,
    required this.variant,
    required this.spec,
    required this.patentResponse,
    this.sessionId,
  });

  @override
  State<PriorArtScreen> createState() => _PriorArtScreenState();
}

class _PriorArtScreenState extends State<PriorArtScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  bool get _canBuildThis {
    if (widget.patentResponse.hits.isEmpty) return true;
    return widget.patentResponse.hits.every((h) => h.score < 0.70);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patent Landscape')),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // Confidence card
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.radar, color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search Confidence',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'How thorough was our search',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    ConfidenceBadge(level: widget.patentResponse.confidence),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Section header
              Row(
                children: [
                  Text(
                    'Prior Art Results',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${widget.patentResponse.hits.length}',
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Patent hits
              if (widget.patentResponse.hits.isEmpty)
                _emptyState()
              else
                ...widget.patentResponse.hits
                    .map((hit) => _PatentHitCard(hit: hit)),

              const SizedBox(height: AppSpacing.xl),
              const DisclaimerBanner(),
              const SizedBox(height: AppSpacing.lg),

              // Export CTA — dark pill (Etsy)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _exportOnePager,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Get your one-pager',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Build This button — teal accent
              if (_canBuildThis) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _navigateToBuildThis,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_outlined, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Let\'s Build This!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(message: 'Putting together your one-pager...'),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.success,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The field is wide open!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No matching patents found — your idea could be a real hero.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  void _navigateToBuildThis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuildThisScreen(
          productText: widget.product.text,
          variant: widget.variant,
          spec: widget.spec,
          hits: widget.patentResponse.hits,
          sessionId: widget.sessionId,
        ),
      ),
    );
  }

  Future<void> _exportOnePager() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.exportOnePager(
        product: widget.product,
        variant: widget.variant,
        spec: widget.spec,
        hits: widget.patentResponse.hits,
      );

      if (widget.sessionId != null) {
        ApiClient.instance.updateSession(widget.sessionId!, {
          'export_markdown': response.markdown,
          'export_plain_text': response.plainText,
          'status': 'exported',
        }).catchError((_) {});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportScreen(exportResponse: response),
        ),
      );
    } catch (e) {
      _errorMessage = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _PatentHitCard extends StatefulWidget {
  final PatentHit hit;
  const _PatentHitCard({required this.hit});

  @override
  State<_PatentHitCard> createState() => _PatentHitCardState();
}

class _PatentHitCardState extends State<_PatentHitCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hit = widget.hit;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreBadge(score: hit.score),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hit.patentId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),

                    if (hit.assignee != null || hit.date != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: 4,
                        children: [
                          if (hit.assignee != null)
                            _metaChip(Icons.business_rounded, hit.assignee!),
                          if (hit.date != null)
                            _metaChip(Icons.calendar_today_rounded, hit.date!),
                        ],
                      ),
                    ],

                    const SizedBox(height: AppSpacing.md),

                    // Expandable comparison
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isExpanded ? 'Hide details' : 'How it compares',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warmWhite,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hit.whySimilar,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    height: 1.5,
                                  ),
                            ),
                            if (hit.abstract_.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Divider(color: AppColors.borderLight, height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                hit.abstract_,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.stone),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}
