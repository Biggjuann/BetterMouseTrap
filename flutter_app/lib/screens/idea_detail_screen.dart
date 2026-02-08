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
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero header card — warm cream
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.warmWhite,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              widget.variant.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.variant.summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (_isLoadingSpec)
                  _buildLoadingState()
                else if (_spec != null) ...[
                  _specSection(_spec!),
                ],

                const SizedBox(height: AppSpacing.lg),
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
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Breaking down what makes this clever...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.stone,
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
          Icons.auto_awesome_outlined,
          AppColors.amber,
        ),
        const SizedBox(height: AppSpacing.md),
        _specCard(
          'How It Works',
          spec.mechanism,
          Icons.settings_suggest_outlined,
          AppColors.teal,
        ),
        const SizedBox(height: AppSpacing.md),
        _specCard(
          'What Exists Today',
          spec.baseline,
          Icons.analytics_outlined,
          AppColors.coral,
        ),
        const SizedBox(height: AppSpacing.md),

        // Differentiators card
        _sectionCard(
          icon: Icons.stars_outlined,
          color: AppColors.success,
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
                            color: AppColors.success.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyMedium,
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
          icon: Icons.label_outline,
          color: AppColors.stone,
          title: 'Keywords',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: spec.keywords.map((k) => KeywordTag(text: k)).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Patent search CTA — dark pill (Etsy)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isLoadingPatents ? null : () => _searchPatents(spec),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_rounded, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Check for existing patents',
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
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
      final response = await ApiClient.instance.searchPatents(
        queries: spec.searchQueries,
        keywords: spec.keywords,
      );

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
