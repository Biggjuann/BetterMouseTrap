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
          ListView(
            padding: const EdgeInsets.all(AppSpacing.base),
            children: [
              // Confidence card
              Container(
                padding: const EdgeInsets.all(AppSpacing.base),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.lightWarmGray.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(Icons.radar, color: Color(0xFF2196F3), size: 20),
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
                                  color: AppColors.darkCharcoal,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'How thorough was our search',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.mutedGray,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ConfidenceBadge(level: widget.patentResponse.confidence),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Section header with count
              Row(
                children: [
                  Text(
                    'Prior Art Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkCharcoal,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryAmber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${widget.patentResponse.hits.length}',
                      style: TextStyle(
                        color: AppColors.primaryAmber,
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

              const SizedBox(height: AppSpacing.lg),
              const DisclaimerBanner(),
              const SizedBox(height: AppSpacing.base),

              // Export button — gradient CTA
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppGradients.hero,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAmber.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _exportOnePager,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.base,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Get your one-pager',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Build This button
              if (_canBuildThis) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.successGreen.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _navigateToBuildThis,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.base,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.rocket_launch_rounded,
                                color: Colors.white, size: 22),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Let\'s Build This!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
        color: AppColors.successGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.successGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.successGreen,
              size: 28,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The field is wide open!',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.successGreen,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No matching patents found — your idea could be a real hero.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.mutedGray,
                ),
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

      // Save export to session (fire and forget)
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.lightWarmGray.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score badge on left
              ScoreBadge(score: hit.score),
              const SizedBox(width: AppSpacing.md),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkCharcoal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hit.patentId,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.mutedGray,
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
                              color: AppColors.primaryAmber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isExpanded ? 'Hide details' : 'How it compares',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.primaryAmber,
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
                          color: AppColors.softCream.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: Border.all(
                            color:
                                AppColors.lightWarmGray.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hit.whySimilar,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.warmGray,
                                    height: 1.5,
                                  ),
                            ),
                            if (hit.abstract_.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Divider(
                                color: AppColors.lightWarmGray
                                    .withValues(alpha: 0.3),
                                height: 1,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                hit.abstract_,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.mutedGray,
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
        Icon(icon, size: 13, color: AppColors.mutedGray),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.mutedGray,
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}
