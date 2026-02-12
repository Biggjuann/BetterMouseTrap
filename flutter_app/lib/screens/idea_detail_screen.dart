import 'package:flutter/material.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/keyword_tag.dart';
import '../widgets/loading_overlay.dart';
import 'prior_art_screen.dart';

class IdeaDetailScreen extends StatefulWidget {
  final IdeaVariant variant;
  final String productText;
  final String? productURL;
  final String? sessionId;

  const IdeaDetailScreen({
    super.key,
    required this.variant,
    required this.productText,
    this.productURL,
    this.sessionId,
  });

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  IdeaSpec? _spec;
  bool _isLoadingSpec = false;
  bool _isLoadingPatents = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpec();
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
              // Sticky header — Stitch style
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.cream.withValues(alpha: 0.8),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
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
                title: Column(
                  children: [
                    Text(
                      'IDEA DEEP DIVE',
                      style: TextStyle(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      widget.variant.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                actions: [
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
                        Icons.more_horiz,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    onPressed: () {},
                  ),
                ],
              ),

              // Hero card — gradient overlay like Stitch
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 0,
                  ),
                  child: Container(
                    width: double.infinity,
                    height: 192,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      gradient: AppGradients.hero,
                      boxShadow: AppShadows.elevated,
                    ),
                    child: Stack(
                      children: [
                        // Gradient overlay for text readability
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              gradient: AppGradients.cardOverlay,
                            ),
                          ),
                        ),
                        // Text at bottom
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Text(
                            widget.variant.summary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Keyword pills — Stitch
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.variant.keywords
                        .map((k) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                border: Border.all(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                '#$k',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),

              // Spec content or loading
              if (_isLoadingSpec)
                SliverToBoxAdapter(child: _buildLoadingState())
              else if (_spec != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _specSection(_spec!),
                  ),
                ),

              // Bottom spacer for fixed footer
              const SliverToBoxAdapter(child: SizedBox(height: 160)),
            ],
          ),

          // Fixed bottom action bar — Stitch
          if (_spec != null && !_isLoadingSpec)
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Check Patents button — Stitch teal
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed:
                            _isLoadingPatents ? null : () => _searchPatents(_spec!),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.teal,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Check Patents'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoadingPatents)
            const LoadingOverlay(
                message:
                    'Analyzing invention & searching patents...\nThis takes 30-60 seconds.'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Breaking down what makes this clever...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _specSection(IdeaSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _specCard(
          'What Makes It Unique',
          spec.novelty,
          Icons.auto_awesome,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.base),
        _specCard(
          'How It Works',
          spec.mechanism,
          Icons.settings_suggest,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.base),
        _specCard(
          'What Exists Today',
          spec.baseline,
          Icons.search,
          AppColors.primary,
        ),
        const SizedBox(height: AppSpacing.base),

        // Differentiators — Stitch: checkmark list
        _sectionCard(
          icon: Icons.verified_user,
          title: 'Key Differentiators',
          child: Column(
            children: spec.differentiators
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          entry.key < spec.differentiators.length - 1 ? 12 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.teal,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.base),

        // Keywords card
        _sectionCard(
          icon: Icons.label_outline,
          title: 'Keywords',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: spec.keywords.map((k) => KeywordTag(text: k)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _specCard(
      String title, String text, IconData icon, Color color) {
    return _sectionCard(
      icon: icon,
      title: title,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.ink,
            ),
      ),
    );
  }

  // Stitch section card: icon + uppercase title + content
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.slateLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Future<void> _loadSpec() async {
    setState(() => _isLoadingSpec = true);
    try {
      final spec = await ApiClient.instance.generateSpec(
        productText: widget.productText,
        variant: widget.variant,
      );
      if (mounted) {
        setState(() => _spec = spec);
        if (widget.sessionId != null) {
          ApiClient.instance.updateSession(widget.sessionId!, {
            'spec_json': spec.toJson(),
            'status': 'spec_generated',
          }).catchError((_) {});
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSpec = false);
    }
  }

  Future<void> _searchPatents(IdeaSpec spec) async {
    setState(() => _isLoadingPatents = true);
    try {
      final analysisResponse = await ApiClient.instance.analyzePatents(
        productText: widget.productText,
        variant: widget.variant,
        spec: spec,
      );

      if (widget.sessionId != null) {
        ApiClient.instance.updateSession(widget.sessionId!, {
          'patent_hits_json':
              analysisResponse.hits.map((h) => h.toJson()).toList(),
          'patent_confidence': analysisResponse.confidence,
          'status': 'patents_searched',
        }).catchError((_) {});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PriorArtScreen(
            product: ProductInput(
              text: widget.productText,
              url: widget.productURL,
            ),
            variant: widget.variant,
            spec: spec,
            analysisResponse: analysisResponse,
            sessionId: widget.sessionId,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPatents = false);
    }
  }
}
