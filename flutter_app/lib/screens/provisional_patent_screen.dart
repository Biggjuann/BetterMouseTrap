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
              // ── Stitch nav bar ──────────────────────────────────────
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
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'PATENT APPLICATION',
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
                        ),
                        if (_draft != null)
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
                                Icons.picture_as_pdf,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            onPressed: _downloadPdf,
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      _buildInfoCard(),
                      const SizedBox(height: AppSpacing.lg),

                      if (_draft == null) ...[
                        // What you'll get section
                        _buildWhatYouGetSection(),
                        const SizedBox(height: AppSpacing.lg),
                        const DisclaimerBanner(),
                        // Extra spacing for fixed button
                        const SizedBox(height: 120),
                      ] else ...[
                        // Action bar: Copy + PDF
                        _buildActionBar(),
                        const SizedBox(height: AppSpacing.sm),
                        // Rendered markdown in Stitch card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: AppColors.cardWhite,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.05),
                            ),
                            boxShadow: AppShadows.elevated,
                          ),
                          child: MarkdownBody(
                            data: _draft!.markdown,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              h1: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                height: 1.3,
                              ),
                              h2: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.3,
                                height: 1.4,
                              ),
                              h3: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                                height: 1.4,
                              ),
                              h4: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink.withValues(alpha: 0.8),
                                fontStyle: FontStyle.italic,
                                height: 1.4,
                              ),
                              p: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.ink,
                                height: 1.6,
                              ),
                              strong: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                              em: const TextStyle(
                                fontFamily: 'Manrope',
                                fontStyle: FontStyle.italic,
                                color: AppColors.ink,
                              ),
                              listBullet: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                  ),
                                ),
                              ),
                              h1Padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                                bottom: AppSpacing.md,
                              ),
                              h2Padding: const EdgeInsets.only(
                                top: AppSpacing.lg,
                                bottom: AppSpacing.sm,
                              ),
                              h3Padding: const EdgeInsets.only(
                                top: AppSpacing.md,
                                bottom: AppSpacing.xs,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const DisclaimerBanner(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Fixed bottom Generate button ──────────────────────────
          if (_draft == null && !_isLoading)
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
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      boxShadow: AppShadows.button,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    child: FilledButton(
                      onPressed: _generateDraft,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.teal,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 20),
                          SizedBox(width: AppSpacing.sm),
                          Text('Draft Patent Application'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          if (_isLoading)
            const LoadingOverlay(
              message: 'Drafting your provisional patent application...\nThis may take 30-60 seconds.',
            ),
        ],
      ),
    );
  }

  // ── Info card: what is a provisional patent ──────────────────────

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.gavel, color: AppColors.teal, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'USPTO PROVISIONAL PATENT',
                      style: TextStyle(
                        color: AppColors.slateLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Protect Your Idea',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'A provisional patent application establishes your priority date — '
            'proving you had the idea first. You then have 12 months to file '
            'a full (nonprovisional) application.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Key facts row
          Row(
            children: [
              _factChip(Icons.schedule, '12-month window'),
              const SizedBox(width: AppSpacing.sm),
              _factChip(Icons.flag, 'Priority date'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _factChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.teal),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── What You'll Get section ─────────────────────────────────────

  Widget _buildWhatYouGetSection() {
    final sections = [
      ('Cover Sheet', 'Formal invention title and filing notes', Icons.article_outlined),
      ('Specification', 'Background, summary, and detailed description', Icons.description_outlined),
      ('Abstract', '~150-word technical summary', Icons.short_text),
      ('Claims', 'Independent and dependent patent claims', Icons.checklist),
      ('Drawings Guide', 'Recommended figures to prepare', Icons.draw_outlined),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
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
              Icon(Icons.list_alt, color: AppColors.primary, size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(
                'WHAT YOU\'LL GET',
                style: TextStyle(
                  color: AppColors.slateLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...sections.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s.$3, size: 16, color: AppColors.teal),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        s.$2,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.stone,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ── Action bar (after generation) ───────────────────────────────

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

  // ── Actions ─────────────────────────────────────────────────────

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
            Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Generation Failed',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The patent draft could not be generated. This usually means the AI service is temporarily busy.',
              style: TextStyle(color: AppColors.ink, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                error.length > 200 ? '${error.substring(0, 200)}...' : error,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: AppColors.slateLight,
                ),
              ),
            ),
          ],
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
            style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
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
