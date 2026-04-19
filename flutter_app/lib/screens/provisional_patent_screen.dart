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
import '../widgets/studio_widgets.dart';

// ─────────────────────────────────────────────────────────────────────
// Provisional Patent — Dossier language
//
// Two states:
//   (a) Before drafting  → editorial brief: what this is, what you'll
//                          get back, one clear call to draft.
//   (b) After drafting   → the document itself, rendered on a cream
//                          "page" with Fraunces heads and a file
//                          header. Copy / PDF live in a slim action rail.
// ─────────────────────────────────────────────────────────────────────

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
              _Header(
                onBack: () => Navigator.pop(context),
                trailing: hasDraft
                    ? IconBtn(icon: Icons.ios_share_rounded, onPressed: _downloadPdf)
                    : null,
                label: hasDraft ? 'THE DRAFT' : 'FILING PREP',
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

  // ── Actions ─────────────────────────────────────────────────────

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
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: Text('The draft didn\'t land', style: AppText.display4),
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
                  fontFamily: fontMono, fontSize: 11,
                  color: AppColors.graphite, height: 1.5,
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

// ── Layout constants ────────────────────────────────────────────────

const EdgeInsets _pageH = EdgeInsets.symmetric(horizontal: 22);

// ── Header bar ──────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  final Widget? trailing;
  final String label;
  const _Header({required this.onBack, required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            IconBtn(icon: Icons.arrow_back_rounded, onPressed: onBack),
            const Spacer(),
            Text(label, style: AppText.monoMeta),
            const Spacer(),
            trailing ?? const SizedBox(width: 40),
          ],
        ),
      ),
    );
  }
}

// ── BEFORE: the brief ───────────────────────────────────────────────

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
          padding: const EdgeInsets.only(bottom: 140),
          children: [
            // Masthead
            Padding(
              padding: _pageH.copyWith(top: 8, bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text('File Nº $fileNumber', style: AppText.monoMeta),
                    const SizedBox(width: 10),
                    Text('·', style: AppText.monoMeta),
                    const SizedBox(width: 10),
                    Text('Provisional'.toUpperCase(), style: AppText.monoMeta),
                  ]),
                  const SizedBox(height: 18),
                  Text('The ', style: AppText.display2.copyWith(color: AppColors.mist)),
                  RichText(
                    text: TextSpan(
                      style: AppText.display1,
                      children: [
                        const TextSpan(text: 'filing for '),
                        TextSpan(
                          text: _shorten(title),
                          style: AppText.display1.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.accentInk,
                          ),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // The primer — italic pull paragraph
            Padding(
              padding: _pageH.copyWith(bottom: 36),
              child: StudioCard(
                background: AppColors.accentSoft,
                border: Border.all(color: Colors.transparent),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow('On the page',
                      color: AppColors.accentInk.withValues(alpha: 0.6)),
                    const SizedBox(height: 10),
                    Text(
                      'A date stamp on your idea.',
                      style: AppText.display3.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.accentInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'A provisional patent establishes your priority — proof that '
                      'you had the idea first. From the moment it\'s filed, you have '
                      'twelve months to turn it into a full (non-provisional) application.',
                      style: AppText.bodyLg.copyWith(
                        height: 1.6,
                        color: AppColors.accentInk,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _FactPill(number: '12', unit: 'months', label: 'to file a full app.'),
                        const SizedBox(width: 14),
                        _FactPill(number: '01', unit: 'day', label: 'priority secured.'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // What we'll hand back
            Padding(
              padding: _pageH.copyWith(bottom: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    eyebrow: 'I · The package',
                    title: 'What we\'ll hand back',
                    trailing: '5 sections',
                  ),
                  _PackageRow(n: 1, title: 'Cover sheet',   note: 'Formal title and filing notes.'),
                  _PackageRow(n: 2, title: 'Specification', note: 'Background, summary, detailed description.'),
                  _PackageRow(n: 3, title: 'Abstract',      note: 'A 150-word technical summary.'),
                  _PackageRow(n: 4, title: 'Claims',        note: 'Independent and dependent, drafted in form.'),
                  _PackageRow(n: 5, title: 'Drawings guide',note: 'The figures to prepare, annotated.', isLast: true),
                ],
              ),
            ),

            // The small print
            Padding(
              padding: _pageH.copyWith(bottom: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2, right: 10),
                      child: Icon(Icons.info_outline_rounded, size: 14, color: AppColors.mist),
                    ),
                    Expanded(
                      child: Text(
                        'This is a drafting aid, not legal advice. Before filing with the USPTO, '
                        'have a licensed attorney review the document.',
                        style: AppText.bodySm.copyWith(color: AppColors.graphite, height: 1.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Fixed bottom CTA
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: 0.95),
                border: const Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: StudioButton(
                label: 'Draft the provisional',
                icon: Icons.edit_note_rounded,
                kind: BtnKind.primary,
                onPressed: onDraft,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _shorten(String s) {
    final words = s.split(' ');
    if (words.length <= 5) return s;
    return '${words.take(5).join(' ')}…';
  }
}

class _FactPill extends StatelessWidget {
  final String number;
  final String unit;
  final String label;
  const _FactPill({required this.number, required this.unit, required this.label});

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
                style: AppText.display2.copyWith(
                  color: AppColors.accentInk,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const WidgetSpan(child: SizedBox(width: 4)),
              TextSpan(
                text: unit,
                style: AppText.monoMeta.copyWith(color: AppColors.accentInk),
              ),
            ]),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.bodySm.copyWith(color: AppColors.accentInk, height: 1.4)),
        ],
      ),
    );
  }
}

class _PackageRow extends StatelessWidget {
  final int n;
  final String title;
  final String note;
  final bool isLast;
  const _PackageRow({required this.n, required this.title, required this.note, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.rule),
          bottom: isLast ? const BorderSide(color: AppColors.rule) : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: Text(n.toString().padLeft(2, '0'),
              style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.display4.copyWith(fontSize: 18)),
                const SizedBox(height: 3),
                Text(note, style: AppText.body.copyWith(color: AppColors.graphite, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── AFTER: the drafted document ─────────────────────────────────────

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
        // Document masthead strip
        Padding(
          padding: _pageH.copyWith(top: 6, bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'File Nº $fileNumber  ·  ${draft.coverSheet.filingDateNote}',
                  style: AppText.monoMeta,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _InlineAction(icon: Icons.copy_rounded, label: 'Copy', onTap: onCopy),
              const SizedBox(width: 10),
              _InlineAction(icon: Icons.picture_as_pdf_outlined, label: 'PDF', onTap: onPdf),
            ],
          ),
        ),

        // The document — cream "page" sheet with hairline
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.hairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top marque
                  Container(
                    width: 32, height: 2, color: AppColors.accentInk,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Provisional Patent Application'.toUpperCase(),
                    style: AppText.monoMeta,
                  ),
                  const SizedBox(height: 6),
                  Text(draft.coverSheet.inventionTitle,
                    style: AppText.display2.copyWith(height: 1.1)),
                  const SizedBox(height: 22),

                  MarkdownBody(
                    data: draft.markdown,
                    selectable: true,
                    styleSheet: _markdownStyle(context),
                  ),

                  const SizedBox(height: 28),
                  Container(height: 1, color: AppColors.hairline),
                  const SizedBox(height: 14),
                  Text(
                    'Drafted ${draft.coverSheet.filingDateNote}. Review before filing.',
                    style: AppText.monoMeta,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    return MarkdownStyleSheet(
      h1: AppText.display3.copyWith(height: 1.2),
      h2: TextStyle(
        fontFamily: fontDisplay, fontSize: 22, fontWeight: FontWeight.w400,
        color: AppColors.ink, height: 1.25, letterSpacing: -0.4,
      ),
      h3: TextStyle(
        fontFamily: fontDisplay, fontSize: 17, fontWeight: FontWeight.w500,
        color: AppColors.ink, fontStyle: FontStyle.italic, height: 1.3,
      ),
      h4: AppText.monoMeta.copyWith(color: AppColors.accentInk),
      p: AppText.body.copyWith(height: 1.65),
      strong: const TextStyle(fontFamily: fontSans, fontWeight: FontWeight.w600, color: AppColors.ink),
      em: TextStyle(fontFamily: fontSans, fontStyle: FontStyle.italic, color: AppColors.ink),
      listBullet: AppText.body.copyWith(color: AppColors.accentInk),
      blockquote: AppText.body.copyWith(
        fontStyle: FontStyle.italic, color: AppColors.accentInk, height: 1.6,
      ),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.accentInk, width: 2)),
      ),
      blockquotePadding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      code: TextStyle(
        fontFamily: fontMono, fontSize: 12.5, color: AppColors.graphite,
        backgroundColor: AppColors.bg,
      ),
      horizontalRuleDecoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      h1Padding: const EdgeInsets.only(top: 14, bottom: 10),
      h2Padding: const EdgeInsets.only(top: 22, bottom: 8),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 4),
      h4Padding: const EdgeInsets.only(top: 12, bottom: 2),
      blockSpacing: 12,
    );
  }
}

class _InlineAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _InlineAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: AppColors.graphite),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: fontSans, fontSize: 11, fontWeight: FontWeight.w600,
                color: AppColors.graphite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
