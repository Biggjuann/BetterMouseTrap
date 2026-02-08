import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
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
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Confidence row
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Text(
                        'How thorough was our search',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const Spacer(),
                      ConfidenceBadge(
                        level: widget.patentResponse.confidence,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Section header
              Text(
                'Here\'s what\'s already out there',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // Patent hits
              if (widget.patentResponse.hits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No matching patents found — the field is wide open!',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...widget.patentResponse.hits
                    .map((hit) => _PatentHitCard(hit: hit)),

              const SizedBox(height: 16),
              const DisclaimerBanner(),
              const SizedBox(height: 16),

              // Export button
              FilledButton.icon(
                onPressed: _isLoading ? null : _exportOnePager,
                icon: const Icon(Icons.description),
                label: const Text('Get your one-pager'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),

              // Build This button (only when low patent overlap)
              if (_canBuildThis) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _navigateToBuildThis,
                  icon: const Icon(Icons.build),
                  label: const Text('Let\'s Build This!'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(message: 'Putting together your one-pager...'),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title + score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hit.patentId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ScoreBadge(score: hit.score),
              ],
            ),

            if (hit.assignee != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hit.assignee!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ),
                ],
              ),
            ],

            if (hit.date != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    hit.date!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),

            // Expandable "Why similar"
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How it compares',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),

            if (_isExpanded) ...[
              const SizedBox(height: 6),
              Text(
                hit.whySimilar,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              if (hit.abstract_.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  hit.abstract_,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
