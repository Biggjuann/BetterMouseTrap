import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/api_responses.dart';
import '../theme.dart';
import '../utils/pdf_downloader.dart';
import '../utils/pdf_generator.dart';
import '../widgets/whiskers_widgets.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
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
                  const SizedBox(width: 4),
                  IconBtn(
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                  ),
                  const Spacer(),
                  Text('The One-Pager', style: AppText.sectionTitle),
                  const Spacer(),
                  IconBtn(
                      icon: Icons.ios_share_rounded,
                      onPressed: () => _pdf(context)),
                ],
              ),
            ),
          ),

          // Document strip
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'File Nº ${_fileNum()}  ·  Invention summary',
                    style: AppText.tiny,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _ActionChip(
                    icon: Icons.copy_rounded,
                    label: 'Copy',
                    onTap: () => _copy(context)),
                const SizedBox(width: 8),
                _ActionChip(
                    icon: Icons.picture_as_pdf_outlined,
                    label: 'PDF',
                    onTap: () => _pdf(context)),
              ],
            ),
          ),

          // Document content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: WCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.lav,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Invention Summary',
                        style: AppText.tiny.copyWith(
                            color: AppColors.lavDark, letterSpacing: 0.8)),
                    const SizedBox(height: 20),
                    MarkdownBody(
                      data: exportResponse.markdown,
                      selectable: true,
                      styleSheet: _mdStyle(),
                    ),
                    const SizedBox(height: 24),
                    Container(height: 1, color: AppColors.hairline),
                    const SizedBox(height: 12),
                    Text(
                      'A drafting aid. Review before sharing.',
                      style: AppText.tiny,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer action bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryBtn(
                      label: 'Copy text',
                      leading: Icons.copy_rounded,
                      onPressed: () => _copy(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SoftBtn(
                      label: 'Save PDF',
                      icon: Icons.picture_as_pdf_outlined,
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

  MarkdownStyleSheet _mdStyle() {
    return MarkdownStyleSheet(
      h1: AppText.display2.copyWith(height: 1.15, color: AppColors.ink),
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
      listBullet: AppText.body.copyWith(color: AppColors.lav),
      blockquote: AppText.body.copyWith(
          fontStyle: FontStyle.italic,
          color: AppColors.lavDark,
          height: 1.6),
      blockquoteDecoration: const BoxDecoration(
          border:
              Border(left: BorderSide(color: AppColors.lav, width: 3))),
      blockquotePadding:
          const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      code: TextStyle(
          fontFamily: fontMono,
          fontSize: 12.5,
          color: AppColors.inkSoft,
          backgroundColor: AppColors.bg),
      horizontalRuleDecoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.hairline))),
      h1Padding: const EdgeInsets.only(top: 10, bottom: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
