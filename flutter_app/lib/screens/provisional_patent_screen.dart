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
import '../widgets/loading_overlay.dart';
import '../widgets/whiskers_widgets.dart';

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

  String _fileNum() {
    final t = widget.variant.title;
    var h = 0;
    for (final c in t.codeUnits) {
      h = (h * 31 + c) & 0xffff;
    }
    return 'PROV-${2000 + (h % 7999)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDraft = _draft != null;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      IconBtn(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      Text(hasDraft ? 'Your Draft' : 'Filing Prep',
                          style: AppText.sectionTitle),
                      const Spacer(),
                      if (hasDraft)
                        IconBtn(
                            icon: Icons.ios_share_rounded,
                            onPressed: _downloadPdf)
                      else
                        const SizedBox(width: 36),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: hasDraft
                    ? _DraftView(
                        draft: _draft!,
                        onCopy: _copyToClipboard,
                        onPdf: _downloadPdf,
                        fileNumber: _fileNum(),
                      )
                    : _BriefView(
                        title: widget.variant.title,
                        fileNumber: _fileNum(),
                        onDraft: _generateDraft,
                      ),
              ),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(
              message: 'Drafting your provisional…\nThis takes 30–60 seconds.',
            ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    if (_draft == null) return;
    Clipboard.setData(ClipboardData(text: _draft!.markdown));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
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
          const SnackBar(content: Text('PDF downloaded.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF generation failed: $e')));
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
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: Text("The draft didn't land", style: AppText.display3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The service is likely busy. Try once more — the request is cheap.',
              style: AppText.body.copyWith(height: 1.55),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Text(
                error.length > 200 ? '${error.substring(0, 200)}…' : error,
                style: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 11,
                  color: AppColors.inkSoft,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.lav),
            onPressed: () {
              Navigator.pop(ctx);
              _generateDraft();
            },
            child: const Text('Try again'),
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

// ── Before: brief view ───────────────────────────────────────────────

class _BriefView extends StatelessWidget {
  final String title;
  final String fileNumber;
  final VoidCallback onDraft;
  const _BriefView({
    required this.title,
    required this.fileNumber,
    required this.onDraft,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            // Hero card with guardian mascot
            WCard(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), AppColors.lavLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('File Nº $fileNumber',
                            style: AppText.tiny
                                .copyWith(color: AppColors.lavDark)),
                        const SizedBox(height: 8),
                        Text('Secure your idea.',
                            style: AppText.display2
                                .copyWith(color: AppColors.ink)),
                        const SizedBox(height: 6),
                        Text(
                          'A provisional establishes priority — proof you had it first.',
                          style: AppText.caption
                              .copyWith(color: AppColors.lavDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Mascot(pose: MascotPose.guardian, size: 72),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What a provisional is
            WCard(
              color: AppColors.lavLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A date stamp on your idea.',
                      style: AppText.bodyBold
                          .copyWith(color: AppColors.lavDark)),
                  const SizedBox(height: 8),
                  Text(
                    'A provisional patent establishes your priority — proof that '
                    'you had the idea first. From the moment it\'s filed, you have '
                    'twelve months to turn it into a full (non-provisional) application.',
                    style: AppText.body.copyWith(
                        height: 1.6, color: AppColors.lavDark),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatPill(number: '12', unit: 'months',
                          label: 'to file a full app.'),
                      const SizedBox(width: 14),
                      _StatPill(number: '01', unit: 'day',
                          label: 'priority secured.'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // What you'll get back
            SectionHeader("What we'll hand back"),
            const SizedBox(height: 8),
            ..._packageItems.asMap().entries.map((e) {
              final (sectionTitle, note) = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.lavLight,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: AppText.bodyBold.copyWith(
                                color: AppColors.lavDark, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sectionTitle, style: AppText.bodyBold),
                            const SizedBox(height: 2),
                            Text(note,
                                style: AppText.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),

            // Disclaimer
            WCard(
              color: AppColors.peachBg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.danger),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is a drafting aid, not legal advice. Before filing with '
                      'the USPTO, have a licensed attorney review the document.',
                      style: AppText.caption
                          .copyWith(color: AppColors.danger, height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Fixed CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.95),
                border: const Border(
                    top: BorderSide(color: AppColors.hairline)),
              ),
              child: PrimaryBtn(
                label: 'Draft the provisional',
                leading: Icons.edit_note_rounded,
                onPressed: onDraft,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static const _packageItems = [
    ('Cover sheet', 'Formal title and filing notes.'),
    ('Specification', 'Background, summary, detailed description.'),
    ('Abstract', 'A 150-word technical summary.'),
    ('Claims', 'Independent and dependent, drafted in form.'),
    ('Drawings guide', 'The figures to prepare, annotated.'),
  ];
}

class _StatPill extends StatelessWidget {
  final String number;
  final String unit;
  final String label;
  const _StatPill(
      {required this.number, required this.unit, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: number,
                style: AppText.display2.copyWith(color: AppColors.lavDark),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: unit,
                style: AppText.tiny
                    .copyWith(color: AppColors.lavDark, fontSize: 11),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.tiny.copyWith(
                  color: AppColors.lavDark, height: 1.4)),
        ],
      ),
    );
  }
}

// ── After: drafted document ──────────────────────────────────────────

class _DraftView extends StatelessWidget {
  final ProvisionalPatentResponse draft;
  final VoidCallback onCopy;
  final VoidCallback onPdf;
  final String fileNumber;

  const _DraftView({
    required this.draft,
    required this.onCopy,
    required this.onPdf,
    required this.fileNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'File Nº $fileNumber  ·  ${draft.coverSheet.filingDateNote}',
                  style: AppText.tiny,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _ActionChip(
                  icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy),
              const SizedBox(width: 8),
              _ActionChip(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  onTap: onPdf),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: WCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 28, height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.lav,
                        borderRadius: BorderRadius.circular(2),
                      )),
                  const SizedBox(height: 14),
                  Text('Provisional Patent Application',
                      style: AppText.tiny
                          .copyWith(color: AppColors.lavDark,
                              letterSpacing: 0.8)),
                  const SizedBox(height: 6),
                  Text(draft.coverSheet.inventionTitle,
                      style: AppText.display2.copyWith(height: 1.1)),
                  const SizedBox(height: 20),
                  MarkdownBody(
                    data: draft.markdown,
                    selectable: true,
                    styleSheet: _mdStyle(),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: AppColors.hairline),
                  const SizedBox(height: 12),
                  Text(
                    'Drafted ${draft.coverSheet.filingDateNote}. Review before filing.',
                    style: AppText.tiny,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _mdStyle() {
    return MarkdownStyleSheet(
      h1: AppText.display3.copyWith(height: 1.2, color: AppColors.ink),
      h2: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.25,
      ),
      h3: TextStyle(
        fontFamily: fontDisplay,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        height: 1.3,
      ),
      h4: AppText.tiny.copyWith(color: AppColors.lavDark, letterSpacing: 0.5),
      p: AppText.body.copyWith(height: 1.65, color: AppColors.ink),
      strong: TextStyle(
          fontFamily: fontSans,
          fontWeight: FontWeight.w700,
          color: AppColors.ink),
      em: TextStyle(
          fontFamily: fontSans,
          fontStyle: FontStyle.italic,
          color: AppColors.ink),
      listBullet:
          AppText.body.copyWith(color: AppColors.lav),
      blockquote: AppText.body.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.lavDark,
          height: 1.6),
      blockquoteDecoration: const BoxDecoration(
        border: Border(
            left: BorderSide(color: AppColors.lav, width: 3)),
      ),
      blockquotePadding:
          const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      code: TextStyle(
          fontFamily: fontMono,
          fontSize: 12.5,
          color: AppColors.inkSoft,
          backgroundColor: AppColors.bg),
      horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline))),
      h1Padding: const EdgeInsets.only(top: 14, bottom: 10),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 14, bottom: 4),
      blockSpacing: 12,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.inkSoft),
            const SizedBox(width: 5),
            Text(label,
                style: AppText.tiny.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}
