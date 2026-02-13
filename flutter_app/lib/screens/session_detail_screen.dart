import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../utils/pdf_downloader.dart';
import '../utils/pdf_generator.dart';
import '../widgets/disclaimer_banner.dart';
import 'provisional_patent_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final String sessionId;
  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  Map<String, dynamic>? _session;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiClient.instance.getSession(widget.sessionId);
      if (mounted) setState(() => _session = data);
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
        title: Text(_session?['title'] ?? 'Session'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.teal,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
              ),
            )
          : _session == null
              ? Center(
                  child: Text(
                    'Session not found',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                )
              : Stack(
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.pageBackground,
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionCard(
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.amber,
                            title: 'Product',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _session!['product_text'] ?? '',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                                ),
                                if (_session!['product_url'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _session!['product_url'],
                                    style: TextStyle(
                                      color: AppColors.teal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          if (_session!['selected_variant_json'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _variantCard(_session!['selected_variant_json']),
                          ],

                          if (_session!['spec_json'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _specCard(_session!['spec_json']),
                          ],

                          if (_session!['patent_confidence'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _sectionCard(
                              icon: Icons.search_rounded,
                              color: AppColors.teal,
                              title: 'Patent Search',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Confidence: ${_session!['patent_confidence']}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
                                  ),
                                  if (_session!['patent_hits_json'] != null)
                                    Text(
                                      '${(_session!['patent_hits_json'] as List).length} hits found',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.ink),
                                    ),
                                  if (_session!['patent_hits_json'] != null &&
                                      _session!['patent_draft_json'] == null &&
                                      _session!['selected_variant_json'] != null &&
                                      _session!['spec_json'] != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _navigateToPatentDraft,
                                        icon: const Icon(Icons.shield_outlined, size: 18),
                                        label: const Text('Draft Patent Application'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.teal,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.md),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],

                          if (_session!['export_markdown'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _markdownCard(
                              icon: Icons.description_outlined,
                              color: AppColors.amber,
                              title: 'Export',
                              markdown: _session!['export_markdown'],
                              copyText: _session!['export_plain_text'] ??
                                  _session!['export_markdown'],
                            ),
                          ],

                          if (_session!['patent_draft_json'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _markdownCard(
                              icon: Icons.shield_outlined,
                              color: const Color(0xFF7B1FA2),
                              title: 'Patent Draft',
                              markdown:
                                  _session!['patent_draft_json']['markdown'] ?? '',
                            ),
                          ],

                          if (_session!['prototype_json'] != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            _markdownCard(
                              icon: Icons.construction_outlined,
                              color: AppColors.teal,
                              title: 'Prototype',
                              markdown:
                                  _session!['prototype_json']['markdown'] ?? '',
                            ),
                          ],

                          const SizedBox(height: AppSpacing.lg),
                          const DisclaimerBanner(),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  void _navigateToPatentDraft() {
    final variant = IdeaVariant.fromJson(
      Map<String, dynamic>.from(_session!['selected_variant_json']),
    );
    final spec = IdeaSpec.fromJson(
      Map<String, dynamic>.from(_session!['spec_json']),
    );
    final hits = (_session!['patent_hits_json'] as List)
        .map((h) => PatentHit.fromJson(Map<String, dynamic>.from(h)))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProvisionalPatentScreen(
          productText: _session!['product_text'] ?? '',
          variant: variant,
          spec: spec,
          hits: hits,
          sessionId: widget.sessionId,
        ),
      ),
    ).then((_) => _loadSession());
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
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
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

  Widget _markdownCard({
    required IconData icon,
    required Color color,
    required String title,
    required String markdown,
    String? copyText,
  }) {
    return _sectionCard(
      icon: icon,
      color: color,
      title: title,
      child: Column(
        children: [
          MarkdownBody(
            data: markdown,
            selectable: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (copyText != null)
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: copyText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text('Copy'),
                ),
              TextButton.icon(
                onPressed: () async {
                  try {
                    final bytes = await PdfGenerator.generateFromMarkdown(
                      title: title,
                      content: markdown,
                    );
                    final safeName = title
                        .replaceAll(RegExp(r'[^\w\s-]'), '')
                        .replaceAll(RegExp(r'\s+'), '_')
                        .toLowerCase();
                    downloadPdfBytes(bytes, '$safeName.pdf');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('PDF downloaded!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _variantCard(Map<String, dynamic> variant) {
    return _sectionCard(
      icon: Icons.lightbulb_outline,
      color: AppColors.amber,
      title: 'Selected Variant',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            variant['title'] ?? 'Untitled',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            variant['summary'] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _specCard(Map<String, dynamic> spec) {
    return _sectionCard(
      icon: Icons.analytics_outlined,
      color: AppColors.coral,
      title: 'Concept Spec',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spec['novelty'] != null) ...[
            Text('Novelty', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink)),
            Text(spec['novelty'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (spec['mechanism'] != null) ...[
            Text('Mechanism', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink)),
            Text(spec['mechanism'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (spec['baseline'] != null) ...[
            Text('Baseline', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.ink)),
            Text(spec['baseline'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.ink)),
          ],
        ],
      ),
    );
  }
}
