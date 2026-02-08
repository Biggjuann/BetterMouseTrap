import 'package:flutter/material.dart';

import '../models/idea_variant.dart';
import '../widgets/keyword_tag.dart';
import '../widgets/mode_badge.dart';
import 'idea_detail_screen.dart';

class IdeasListScreen extends StatelessWidget {
  final List<IdeaVariant> variants;
  final String productText;
  final String? productURL;

  const IdeasListScreen({
    super.key,
    required this.variants,
    required this.productText,
    this.productURL,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ideas')),
      body: ListView.builder(
        itemCount: variants.length,
        itemBuilder: (context, index) {
          final variant = variants[index];
          return _VariantTile(
            variant: variant,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IdeaDetailScreen(
                    variant: variant,
                    productText: productText,
                    productURL: productURL,
                  ),
                ),
              );
            },
          );
        },
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
