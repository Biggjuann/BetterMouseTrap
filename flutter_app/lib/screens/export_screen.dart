import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/api_responses.dart';
import '../theme.dart';
import '../utils/pdf_downloader.dart';
import '../utils/pdf_generator.dart';
import '../widgets/studio_widgets.dart';

// ─────────────────────────────────────────────────────────────────────
// Export — The One-Pager
//
// A single editorial document on a cream "page" sheet. Slim top rail
// with file number + inline Copy / PDF actions. Markdown rendered in
// Fraunces heads, Inter body, with an accent rule at the top of the
// page. Bottom has a pair of StudioButtons for the obvious exits.
// ─────────────────────────────────────────────────────────────────────

class ExportScreen extends StatelessWidget {
  final ExportResponse exportResponse;
  const ExportScreen({super.key, required this.exportResponse});

  String _fileNum() {
    final t = exportResponse.markdown;
    var h = 0;
    for (final c in t.codeUnits) {
      h = (h * 31 + c) & 0xffff;
    }
    return 'OP-${3000 + (h % 6999)}';
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: exportResponse.plainText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard.')),
    );
  }

  Future<void> _pdf(BuildContext context) async {
    try {
      final bytes = await PdfGenerator.generateFromMarkdown(
        title: 'Invention Summary',
        content: exportResponse.markdown,
      );
      downloadPdfBytes(bytes, 'invention_summary.pdf');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // Header bar
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('THE ONE-PAGER', style: AppText.monoMeta),
                  const Spacer(),
                  IconBtn(icon: Icons.ios_share_rounded, onPressed: () => _pdf(context)),
                ],
              ),
            ),
          ),

          // Document strip
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'File Nº ${_fileNum()}  ·  Invention summary',
                    style: AppText.monoMeta,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _InlineAction(icon: Icons.copy_rounded, label: 'Copy', onTap: () => _copy(context)),
                const SizedBox(width: 10),
                _InlineAction(icon: Icons.picture_as_pdf_outlined, label: 'PDF', onTap: () => _pdf(context)),
              ],
            ),
          ),

          // The "page"
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
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
                    Container(width: 32, height: 2, color: AppColors.accentInk),
                    const SizedBox(height: 16),
                    Text('Invention Summary'.toUpperCase(), style: AppText.monoMeta),
                    const SizedBox(height: 20),

                    MarkdownBody(
                      data: exportResponse.markdown,
                      selectable: true,
                      styleSheet: _markdownStyle(),
                    ),

                    const SizedBox(height: 28),
                    Container(height: 1, color: AppColors.hairline),
                    const SizedBox(height: 14),
                    Text(
                      'A drafting aid. Review before sharing.',
                      style: AppText.monoMeta,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer action bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: StudioButton(
                      label: 'Copy text',
                      icon: Icons.copy_rounded,
                      kind: BtnKind.primary,
                      onPressed: () => _copy(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StudioButton(
                      label: 'Save PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      kind: BtnKind.ghost,
                      onPressed: () => _pdf(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  MarkdownStyleSheet _markdownStyle() {
    return MarkdownStyleSheet(
      h1: AppText.display2.copyWith(height: 1.15),
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
      h1Padding: const EdgeInsets.only(top: 10, bottom: 12),
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
