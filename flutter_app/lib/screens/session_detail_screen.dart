import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/api_client.dart';
import '../widgets/disclaimer_banner.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_session?['title'] ?? 'Session'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _session == null
              ? const Center(child: Text('Session not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Product'),
                      Text(_session!['product_text'] ?? ''),
                      if (_session!['product_url'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _session!['product_url'],
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      ],

                      if (_session!['selected_variant_json'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Selected Variant'),
                        _variantCard(_session!['selected_variant_json']),
                      ],

                      if (_session!['spec_json'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Concept Spec'),
                        _specCard(_session!['spec_json']),
                      ],

                      if (_session!['patent_confidence'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Patent Search'),
                        Text('Confidence: ${_session!['patent_confidence']}'),
                        if (_session!['patent_hits_json'] != null)
                          Text(
                              '${(_session!['patent_hits_json'] as List).length} hits found'),
                      ],

                      if (_session!['export_markdown'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Export'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                MarkdownBody(
                                  data: _session!['export_markdown'],
                                  selectable: true,
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(
                                        text: _session!['export_plain_text'] ??
                                            _session!['export_markdown'],
                                      ));
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                        content: Text('Copied to clipboard'),
                                      ));
                                    },
                                    icon: const Icon(Icons.copy, size: 16),
                                    label: const Text('Copy'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      if (_session!['patent_draft_json'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Patent Draft'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: MarkdownBody(
                              data: _session!['patent_draft_json']['markdown'] ??
                                  '',
                              selectable: true,
                            ),
                          ),
                        ),
                      ],

                      if (_session!['prototype_json'] != null) ...[
                        const SizedBox(height: 24),
                        _sectionHeader('Prototype'),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: MarkdownBody(
                              data: _session!['prototype_json']['markdown'] ?? '',
                              selectable: true,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                      const DisclaimerBanner(),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _variantCard(Map<String, dynamic> variant) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              variant['title'] ?? 'Untitled',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(variant['summary'] ?? ''),
          ],
        ),
      ),
    );
  }

  Widget _specCard(Map<String, dynamic> spec) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (spec['novelty'] != null) ...[
              Text('Novelty',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(spec['novelty']),
              const SizedBox(height: 8),
            ],
            if (spec['mechanism'] != null) ...[
              Text('Mechanism',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(spec['mechanism']),
              const SizedBox(height: 8),
            ],
            if (spec['baseline'] != null) ...[
              Text('Baseline',
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(spec['baseline']),
            ],
          ],
        ),
      ),
    );
  }
}
