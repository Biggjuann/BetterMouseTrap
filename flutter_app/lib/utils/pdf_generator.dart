import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Generates a PDF document from a title and markdown-ish content string.
/// Returns the raw PDF bytes for download/sharing.
class PdfGenerator {
  static Future<Uint8List> generateFromMarkdown({
    required String title,
    required String content,
  }) async {
    final pdf = pw.Document();
    final lines = content.split('\n');
    final widgets = <pw.Widget>[];

    for (final line in lines) {
      final trimmed = line.trimRight();

      if (trimmed.isEmpty) {
        widgets.add(pw.SizedBox(height: 6));
        continue;
      }

      if (trimmed.startsWith('---')) {
        widgets.add(pw.Divider(thickness: 0.5));
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Headings
      if (trimmed.startsWith('#### ')) {
        widgets.add(pw.SizedBox(height: 4));
        widgets.add(pw.Text(
          _stripMarkdown(trimmed.substring(5)),
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            fontStyle: pw.FontStyle.italic,
          ),
        ));
        continue;
      }
      if (trimmed.startsWith('### ')) {
        widgets.add(pw.SizedBox(height: 6));
        widgets.add(pw.Text(
          _stripMarkdown(trimmed.substring(4)),
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ));
        continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(pw.SizedBox(height: 8));
        widgets.add(pw.Text(
          _stripMarkdown(trimmed.substring(3)),
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ));
        continue;
      }
      if (trimmed.startsWith('# ')) {
        widgets.add(pw.Text(
          _stripMarkdown(trimmed.substring(2)),
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ));
        widgets.add(pw.SizedBox(height: 4));
        continue;
      }

      // Bullet points
      if (trimmed.startsWith('- ')) {
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('\u2022 ', style: const pw.TextStyle(fontSize: 10)),
              pw.Expanded(
                child: pw.Text(
                  _stripMarkdown(trimmed.substring(2)),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Numbered items (e.g. "1. ")
      final numberedMatch = RegExp(r'^(\d+)\.\s').firstMatch(trimmed);
      if (numberedMatch != null) {
        final num = numberedMatch.group(1)!;
        final text = trimmed.substring(numberedMatch.end);
        widgets.add(pw.Padding(
          padding: const pw.EdgeInsets.only(left: 16),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$num. ',
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Expanded(
                child: pw.Text(
                  _stripMarkdown(text),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
            ],
          ),
        ));
        continue;
      }

      // Italic lines (like disclaimers wrapped in *)
      if (trimmed.startsWith('*') && trimmed.endsWith('*')) {
        widgets.add(pw.Text(
          trimmed.substring(1, trimmed.length - 1),
          style: pw.TextStyle(fontSize: 9, fontStyle: pw.FontStyle.italic),
        ));
        continue;
      }

      // Regular paragraph text
      widgets.add(pw.Text(
        _stripMarkdown(trimmed),
        style: const pw.TextStyle(fontSize: 10),
      ));
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(72), // 1-inch margins
        build: (context) => widgets,
      ),
    );

    return pdf.save();
  }

  /// Remove basic markdown formatting (**bold**, *italic*) for plain-text PDF.
  static String _stripMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1');
  }
}
