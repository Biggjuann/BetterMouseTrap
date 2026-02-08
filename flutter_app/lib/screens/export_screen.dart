import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/api_responses.dart';
import '../widgets/disclaimer_banner.dart';

class ExportScreen extends StatelessWidget {
  final ExportResponse exportResponse;
  const ExportScreen({super.key, required this.exportResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('One-Pager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: exportResponse.plainText),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: exportResponse.markdown,
              selectable: true,
            ),
            const SizedBox(height: 16),
            const DisclaimerBanner(),
          ],
        ),
      ),
    );
  }
}
