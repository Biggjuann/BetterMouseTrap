import 'package:flutter/material.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
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
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Variant header
                Text(
                  widget.variant.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.variant.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 24),

                if (_isLoadingSpec)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Breaking down what makes this clever...'),
                        ],
                      ),
                    ),
                  )
                else if (_spec != null) ...[
                  _specSection(_spec!),
                ],

                const SizedBox(height: 16),
                const DisclaimerBanner(),
              ],
            ),
          ),
          if (_isLoadingPatents)
            const LoadingOverlay(message: 'Checking what\'s already out there...'),
        ],
      ),
    );
  }

  Widget _specSection(IdeaSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _specField('What Makes It Unique', spec.novelty, Icons.auto_awesome),
        const SizedBox(height: 16),
        _specField('How It Works', spec.mechanism, Icons.settings),
        const SizedBox(height: 16),
        _specField('What Exists Today', spec.baseline, Icons.bar_chart),
        const SizedBox(height: 16),

        // Differentiators
        Row(
          children: [
            Icon(Icons.list, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Why It Stands Out',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...spec.differentiators.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(d, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Keywords
        Row(
          children: [
            Icon(Icons.label, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Keywords',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: spec.keywords.map((k) => KeywordTag(text: k)).toList(),
        ),
        const SizedBox(height: 24),

        // Search button
        FilledButton.icon(
          onPressed: _isLoadingPatents ? null : () => _searchPatents(spec),
          icon: const Icon(Icons.search),
          label: const Text('Check for existing patents'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _specField(String title, String text, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
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
