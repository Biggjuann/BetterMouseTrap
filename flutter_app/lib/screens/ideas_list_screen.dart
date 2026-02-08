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
        title: const Text('Ideas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate new ideas',
            onPressed: _isLoading ? null : _regenerate,
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            itemCount: _variants.length,
            itemBuilder: (context, index) {
              final variant = _variants[index];
              return _VariantTile(
                variant: variant,
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
  final VoidCallback onTap;

  const _VariantTile({required this.variant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + mode badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      variant.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ModeBadge(
                    mode: variant.improvementMode,
                    label: variant.modeLabel,
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Summary
              Text(
                variant.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),

              // Keywords (max 4)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: variant.keywords
                    .take(4)
                    .map((k) => KeywordTag(text: k))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
