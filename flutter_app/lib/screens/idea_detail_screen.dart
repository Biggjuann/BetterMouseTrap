import 'package:flutter/material.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/disclaimer_banner.dart';
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
      appBar: AppBar(title: const Text('Your Idea')),
      body: Stack(
        children: [
          // Subtle background gradient
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
                // Hero header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFF8EE), Color(0xFFFFF1DC)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: AppColors.warmGold.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAmber.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              gradient: AppGradients.hero,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryAmber
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lightbulb,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              widget.variant.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.darkCharcoal,
                                    letterSpacing: -0.3,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.variant.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.warmGray,
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (_isLoadingSpec)
                  _buildLoadingState()
                else if (_spec != null) ...[
                  _specSection(_spec!),
                ],

                const SizedBox(height: AppSpacing.base),
                const DisclaimerBanner(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
          if (_isLoadingPatents)
            const LoadingOverlay(
                message: 'Checking what\'s already out there...'),
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
                color: AppColors.primaryAmber,
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            Text(
              'Breaking down what makes this clever...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedGray,
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
          const Color(0xFFEF6C00),
        ),
        const SizedBox(height: AppSpacing.md),
        _specCard(
          'How It Works',
          spec.mechanism,
          Icons.settings_suggest,
          const Color(0xFF2196F3),
        ),
        const SizedBox(height: AppSpacing.md),
        _specCard(
          'What Exists Today',
          spec.baseline,
          Icons.analytics,
          const Color(0xFF00897B),
        ),
        const SizedBox(height: AppSpacing.md),

        // Differentiators card
        _sectionCard(
          icon: Icons.stars,
          color: AppColors.successGreen,
          title: 'Why It Stands Out',
          child: Column(
            children: spec.differentiators
                .asMap()
                .entries
                .map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          entry.key < spec.differentiators.length - 1 ? 10 : 0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: AppColors.successGreen
                                .withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: AppColors.successGreen,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.warmGray,
                                  height: 1.4,
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
        const SizedBox(height: AppSpacing.md),

        // Keywords card
        _sectionCard(
          icon: Icons.label,
          color: AppColors.richBrown,
          title: 'Keywords',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: spec.keywords.map((k) => KeywordTag(text: k)).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Patent search CTA
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
              onTap:
                  _isLoadingPatents ? null : () => _searchPatents(spec),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.base,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Check for existing patents',
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
      ],
    );
  }

  Widget _specCard(
      String title, String text, IconData icon, Color color) {
    return _sectionCard(
      icon: icon,
      color: color,
      title: title,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.warmGray,
              height: 1.5,
            ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkCharcoal,
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
        // Save spec to session (fire and forget)
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
      final response = await ApiClient.instance.searchPatents(
        queries: spec.searchQueries,
        keywords: spec.keywords,
      );

      // Save patent results to session (fire and forget)
      if (widget.sessionId != null) {
        ApiClient.instance.updateSession(widget.sessionId!, {
          'patent_hits_json':
              response.hits.map((h) => h.toJson()).toList(),
          'patent_confidence': response.confidence,
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
            patentResponse: response,
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
