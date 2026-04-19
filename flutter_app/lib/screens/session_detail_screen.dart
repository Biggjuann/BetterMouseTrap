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
import '../widgets/studio_widgets.dart';
import 'provisional_patent_screen.dart';

// ─────────────────────────────────────────────────────────────────────
// Session Detail — The Dossier Volume
//
// A bound dossier of everything recorded in one session: subject line,
// selected idea, spec block, patent search result, export body,
// patent draft, prototype notes. Each is an editorial "section" with
// an eyebrow, serif title, and accent rule.
// ─────────────────────────────────────────────────────────────────────

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _fileNum() {
    var h = 0;
    for (final c in widget.sessionId.codeUnits) {
      h = (h * 31 + c) & 0xffff;
    }
    return 'F-${2000 + (h % 7999)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('THE DOSSIER', style: AppText.monoMeta),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk, strokeWidth: 2))
                  : _session == null
                      ? Center(child: Text('Session not found.', style: AppText.lede))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 6, 22, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildContent(),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    final s = _session!;
    final blocks = <Widget>[];

    // Masthead
    blocks.add(Row(
      children: [
        Container(width: 24, height: 2, color: AppColors.accentInk),
        const SizedBox(width: 10),
        Text('FILE · ${_fileNum()}', style: AppText.monoMeta),
      ],
    ));
    blocks.add(const SizedBox(height: 12));
    blocks.add(Text(
      s['title']?.toString() ?? 'Untitled session',
      style: AppText.display1,
    ));
    blocks.add(const SizedBox(height: 20));

    // Subject
    blocks.add(_Section(
      eyebrow: 'THE SUBJECT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['product_text'] ?? '', style: AppText.body.copyWith(height: 1.6)),
          if (s['product_url'] != null) ...[
            const SizedBox(height: 6),
            Text(
              s['product_url'],
              style: AppText.caption.copyWith(color: AppColors.accentInk),
            ),
          ],
        ],
      ),
    ));

    if (s['selected_variant_json'] != null) {
      final v = s['selected_variant_json'];
      blocks.add(_Section(
        eyebrow: 'THE SELECTED IDEA',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v['title'] ?? 'Untitled', style: AppText.display3),
            const SizedBox(height: 8),
            Text(v['summary'] ?? '', style: AppText.body.copyWith(height: 1.6)),
          ],
        ),
      ));
    }

    if (s['spec_json'] != null) {
      final spec = s['spec_json'];
      blocks.add(_Section(
        eyebrow: 'THE SPEC',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spec['novelty'] != null) _specRow('Novelty', spec['novelty']),
            if (spec['mechanism'] != null) _specRow('Mechanism', spec['mechanism']),
            if (spec['baseline'] != null) _specRow('Baseline', spec['baseline']),
          ],
        ),
      ));
    }

    if (s['patent_confidence'] != null) {
      blocks.add(_Section(
        eyebrow: 'PRIOR ART',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verdict · ${s['patent_confidence']}',
              style: AppText.body.copyWith(fontStyle: FontStyle.italic),
            ),
            if (s['patent_hits_json'] != null) ...[
              const SizedBox(height: 4),
              Text(
                '${(s['patent_hits_json'] as List).length} candidate references on file.',
                style: AppText.caption,
              ),
            ],
            if (s['patent_hits_json'] != null &&
                s['patent_draft_json'] == null &&
                s['selected_variant_json'] != null &&
                s['spec_json'] != null) ...[
              const SizedBox(height: 14),
              StudioButton(
                label: 'Draft patent application',
                icon: Icons.shield_outlined,
                kind: BtnKind.primary,
                onPressed: _navigateToPatentDraft,
              ),
            ],
          ],
        ),
      ));
    }

    if (s['export_markdown'] != null) {
      blocks.add(_Section(
        eyebrow: 'THE ONE-PAGER',
        child: _markdownBlock(
          markdown: s['export_markdown'],
          copyText: s['export_plain_text'] ?? s['export_markdown'],
          pdfTitle: 'Invention Summary',
        ),
      ));
    }

    if (s['patent_draft_json'] != null) {
      blocks.add(_Section(
        eyebrow: 'THE PATENT DRAFT',
        child: _markdownBlock(
          markdown: s['patent_draft_json']['markdown'] ?? '',
          copyText: s['patent_draft_json']['markdown'] ?? '',
          pdfTitle: 'Patent Draft',
        ),
      ));
    }

    if (s['prototype_json'] != null) {
      blocks.add(_Section(
        eyebrow: 'THE PROTOTYPE',
        child: _markdownBlock(
          markdown: s['prototype_json']['markdown'] ?? '',
          copyText: s['prototype_json']['markdown'] ?? '',
          pdfTitle: 'Prototype',
        ),
      ));
    }

    blocks.add(const SizedBox(height: 8));
    blocks.add(Text(
      'A drafting aid. Review before sharing.',
      style: AppText.monoMeta,
    ));

    return blocks;
  }

  Widget _specRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.monoMeta),
          const SizedBox(height: 4),
          Text(text, style: AppText.body.copyWith(height: 1.55)),
        ],
      ),
    );
  }

  Widget _markdownBlock({
    required String markdown,
    required String copyText,
    required String pdfTitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MarkdownBody(
          data: markdown,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            h1: AppText.display3,
            h2: TextStyle(fontFamily: fontDisplay, fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink),
            h3: TextStyle(fontFamily: fontDisplay, fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink, fontStyle: FontStyle.italic),
            p: AppText.body.copyWith(height: 1.6),
            strong: TextStyle(fontFamily: fontSans, fontWeight: FontWeight.w600, color: AppColors.ink),
            em: TextStyle(fontFamily: fontSans, fontStyle: FontStyle.italic, color: AppColors.ink),
            listBullet: AppText.body.copyWith(color: AppColors.accentInk),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copyText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard.')),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 14),
              label: Text('Copy', style: AppText.caption.copyWith(color: AppColors.graphite)),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  final bytes = await PdfGenerator.generateFromMarkdown(
                    title: pdfTitle,
                    content: markdown,
                  );
                  final safeName = pdfTitle
                      .replaceAll(RegExp(r'[^\w\s-]'), '')
                      .replaceAll(RegExp(r'\s+'), '_')
                      .toLowerCase();
                  downloadPdfBytes(bytes, '$safeName.pdf');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF downloaded.')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF failed: $e')));
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
              label: Text('PDF', style: AppText.caption.copyWith(color: AppColors.graphite)),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToPatentDraft() {
    final variant = IdeaVariant.fromJson(Map<String, dynamic>.from(_session!['selected_variant_json']));
    final spec = IdeaSpec.fromJson(Map<String, dynamic>.from(_session!['spec_json']));
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
}

class _Section extends StatelessWidget {
  final String eyebrow;
  final Widget child;
  const _Section({required this.eyebrow, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: AppColors.hairline),
          const SizedBox(height: 14),
          Text(eyebrow, style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
