import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/provisional_patent.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../utils/pdf_downloader.dart';
import '../utils/pdf_generator.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';

class ProvisionalPatentScreen extends StatefulWidget {
  final String productText;
  final IdeaVariant variant;
  final IdeaSpec spec;
  final List<PatentHit> hits;
  final String? sessionId;

  const ProvisionalPatentScreen({
    super.key,
    required this.productText,
    required this.variant,
    required this.spec,
    required this.hits,
    this.sessionId,
  });

  @override
  State<ProvisionalPatentScreen> createState() =>
      _ProvisionalPatentScreenState();
}

class _ProvisionalPatentScreenState extends State<ProvisionalPatentScreen> {
  ProvisionalPatentResponse? _draft;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          Column(
            children: [
              // Nav bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 28),
                          color: AppColors.primary,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Patent Application Draft',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        if (_draft != null)
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 22),
                            color: AppColors.primary,
                            onPressed: _copyToClipboard,
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header card explaining provisional patents
                      _buildHeaderCard(),
                      const SizedBox(height: AppSpacing.lg),

                      if (_draft == null) ...[
                        _buildGenerateButton(),
                      ] else ...[
                        // Action bar: Copy + PDF
                        _buildActionBar(),
                        const SizedBox(height: AppSpacing.sm),
                        // Rendered markdown
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppShadows.elevated,
                          ),
                          child: MarkdownBody(
                            data: _draft!.markdown,
                            selectable: true,
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),
                      const DisclaimerBanner(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(
                message: 'Drafting your provisional patent application...'),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.gavel, color: Colors.white, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'USPTO Provisional Patent',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Generates a draft provisional patent application '
                  'following USPTO guidelines under 35 U.S.C. \u00A7111(b). '
                  'Filing establishes a priority date with a 12-month '
                  'pendency period.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: AppShadows.button,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: FilledButton(
          onPressed: _isLoading ? null : _generateDraft,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7B1FA2),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Draft Patent Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _copyToClipboard,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy'),
        ),
        const SizedBox(width: AppSpacing.sm),
        TextButton.icon(
          onPressed: _downloadPdf,
          icon: const Icon(Icons.picture_as_pdf, size: 16),
          label: const Text('PDF'),
        ),
      ],
    );
  }

  void _copyToClipboard() {
    if (_draft == null) return;
    Clipboard.setData(ClipboardData(text: _draft!.markdown));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Copied to clipboard!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Future<void> _downloadPdf() async {
    if (_draft == null) return;
    try {
      final bytes = await PdfGenerator.generateFromMarkdown(
        title: _draft!.coverSheet.inventionTitle,
        content: _draft!.markdown,
      );
      final safeName = _draft!.coverSheet.inventionTitle
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_');
      downloadPdfBytes(bytes, 'provisional_patent_$safeName.pdf');
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
          SnackBar(content: Text('PDF generation failed: $e')),
        );
      }
    }
  }

  Future<void> _generateDraft() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiClient.instance.generatePatentDraft(
        productText: widget.productText,
        variant: widget.variant,
        spec: widget.spec,
        hits: widget.hits,
      );
      if (mounted) {
        setState(() => _draft = result);
        _saveToSession(result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 24),
            const SizedBox(width: AppSpacing.sm),
            const Text('Generation Failed'),
          ],
        ),
        content: Text(
          error,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _generateDraft();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _saveToSession(ProvisionalPatentResponse draft) {
    if (widget.sessionId == null) return;
    ApiClient.instance
        .updateSession(widget.sessionId!, {
          'patent_draft_json': {
            'cover_sheet': {
              'invention_title': draft.coverSheet.inventionTitle,
              'filing_date_note': draft.coverSheet.filingDateNote,
            },
            'abstract': draft.abstract_,
            'claims': draft.claims,
            'drawings_note': draft.drawingsNote,
            'markdown': draft.markdown,
          },
        })
        .catchError((_) {});
  }
}
