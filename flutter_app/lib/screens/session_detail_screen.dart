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
import '../widgets/whiskers_widgets.dart';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 4),
                  IconBtn(
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                  ),
                  const Spacer(),
                  Text('Session', style: AppText.sectionTitle),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.lav, strokeWidth: 2))
                  : _session == null
                      ? Center(
                          child: Text('Session not found.',
                              style: AppText.bodyLg))
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 6, 20, 36),
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

    // Hero card with inventor mascot
    blocks.add(WCard(
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
                Text('File · ${_fileNum()}',
                    style: AppText.tiny
                        .copyWith(color: AppColors.lavDark)),
                const SizedBox(height: 8),
                Text(
                  s['title']?.toString() ?? 'Untitled session',
                  style: AppText.display2
                      .copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Mascot(pose: MascotPose.inventor, size: 64),
        ],
      ),
    ));
    blocks.add(const SizedBox(height: 20));

    // Subject
    blocks.add(SectionHeader('The Subject'));
    blocks.add(const SizedBox(height: 8));
    blocks.add(WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s['product_text'] ?? '',
              style: AppText.body.copyWith(height: 1.6, color: AppColors.ink)),
          if (s['product_url'] != null) ...[
            const SizedBox(height: 6),
            Text(
              s['product_url'],
              style: AppText.caption
                  .copyWith(color: AppColors.lavDark),
            ),
          ],
        ],
      ),
    ));
    blocks.add(const SizedBox(height: 20));

    if (s['selected_variant_json'] != null) {
      final v = s['selected_variant_json'];
      blocks.add(SectionHeader('Selected Idea'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(v['title'] ?? 'Untitled',
                style: AppText.display3
                    .copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(v['summary'] ?? '',
                style: AppText.body
                    .copyWith(height: 1.6, color: AppColors.ink)),
          ],
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    if (s['spec_json'] != null) {
      final spec = s['spec_json'];
      blocks.add(SectionHeader('The Spec'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spec['novelty'] != null)
              _specRow('Novelty', spec['novelty']),
            if (spec['mechanism'] != null)
              _specRow('Mechanism', spec['mechanism']),
            if (spec['baseline'] != null)
              _specRow('Baseline', spec['baseline']),
          ],
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    if (s['patent_confidence'] != null) {
      blocks.add(SectionHeader('Prior Art'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined,
                    size: 14, color: AppColors.lav),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Verdict · ${s['patent_confidence']}',
                    style: AppText.body.copyWith(
                        fontStyle: FontStyle.italic,
                        color: AppColors.ink),
                  ),
                ),
              ],
            ),
            if (s['patent_hits_json'] != null) ...[
              const SizedBox(height: 6),
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
              PrimaryBtn(
                label: 'Draft patent application',
                leading: Icons.shield_outlined,
                onPressed: _navigateToPatentDraft,
              ),
            ],
          ],
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    if (s['export_markdown'] != null) {
      blocks.add(SectionHeader('The One-Pager'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: _markdownBlock(
          markdown: s['export_markdown'],
          copyText: s['export_plain_text'] ?? s['export_markdown'],
          pdfTitle: 'Invention Summary',
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    if (s['patent_draft_json'] != null) {
      blocks.add(SectionHeader('The Patent Draft'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: _markdownBlock(
          markdown: s['patent_draft_json']['markdown'] ?? '',
          copyText: s['patent_draft_json']['markdown'] ?? '',
          pdfTitle: 'Patent Draft',
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    if (s['prototype_json'] != null) {
      blocks.add(SectionHeader('The Prototype'));
      blocks.add(const SizedBox(height: 8));
      blocks.add(WCard(
        child: _markdownBlock(
          markdown: s['prototype_json']['markdown'] ?? '',
          copyText: s['prototype_json']['markdown'] ?? '',
          pdfTitle: 'Prototype',
        ),
      ));
      blocks.add(const SizedBox(height: 20));
    }

    blocks.add(Text(
      'A drafting aid. Review before sharing.',
      style: AppText.tiny,
    ));

    return blocks;
  }

  Widget _specRow(String label, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppText.tiny.copyWith(
                  color: AppColors.lavDark, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(text,
              style: AppText.body
                  .copyWith(height: 1.55, color: AppColors.ink)),
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
            h1: AppText.display3
                .copyWith(color: AppColors.ink),
            h2: TextStyle(
                fontFamily: fontDisplay,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink),
            h3: TextStyle(
                fontFamily: fontDisplay,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                fontStyle: FontStyle.italic),
            p: AppText.body
                .copyWith(height: 1.6, color: AppColors.ink),
            strong: TextStyle(
                fontFamily: fontSans,
                fontWeight: FontWeight.w700,
                color: AppColors.ink),
            em: TextStyle(
                fontFamily: fontSans,
                fontStyle: FontStyle.italic,
                color: AppColors.ink),
            listBullet: AppText.body.copyWith(color: AppColors.lav),
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
              icon: const Icon(Icons.copy_rounded,
                  size: 14, color: AppColors.inkSoft),
              label: Text('Copy',
                  style: AppText.caption
                      .copyWith(color: AppColors.inkSoft)),
            ),
            TextButton.icon(
              onPressed: () async {
                try {
                  final bytes =
                      await PdfGenerator.generateFromMarkdown(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF failed: $e')));
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf_outlined,
                  size: 14, color: AppColors.inkSoft),
              label: Text('PDF',
                  style: AppText.caption
                      .copyWith(color: AppColors.inkSoft)),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToPatentDraft() {
    final variant = IdeaVariant.fromJson(
        Map<String, dynamic>.from(_session!['selected_variant_json']));
    final spec = IdeaSpec.fromJson(
        Map<String, dynamic>.from(_session!['spec_json']));
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
