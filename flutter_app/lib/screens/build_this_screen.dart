import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/provisional_patent.dart';
import '../models/prototyping_response.dart';
import '../services/api_client.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';

class BuildThisScreen extends StatefulWidget {
  final String productText;
  final IdeaVariant variant;
  final IdeaSpec spec;
  final List<PatentHit> hits;
  final String? sessionId;

  const BuildThisScreen({
    super.key,
    required this.productText,
    required this.variant,
    required this.spec,
    required this.hits,
    this.sessionId,
  });

  @override
  State<BuildThisScreen> createState() => _BuildThisScreenState();
}

class _BuildThisScreenState extends State<BuildThisScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ProvisionalPatentResponse? _patentDraft;
  PrototypingResponse? _prototype;
  bool _isLoadingPatent = false;
  bool _isLoadingPrototype = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Build This'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.description), text: 'Patent Draft'),
            Tab(icon: Icon(Icons.build), text: 'Prototype'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _patentTab(),
          _prototypeTab(),
        ],
      ),
    );
  }

  Widget _patentTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provisional Patent Application',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Generate a draft provisional patent application based on your idea spec and prior art search.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              if (_patentDraft == null)
                FilledButton.icon(
                  onPressed: _isLoadingPatent ? null : _generatePatentDraft,
                  icon: const Icon(Icons.description),
                  label: const Text('Generate Patent Draft'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _patentDraft!.markdown));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: _patentDraft!.markdown,
                  selectable: true,
                ),
              ],

              const SizedBox(height: 16),
              const DisclaimerBanner(),
            ],
          ),
        ),
        if (_isLoadingPatent)
          const LoadingOverlay(message: 'Drafting patent application...'),
      ],
    );
  }

  Widget _prototypeTab() {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Prototyping Package',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Get practical fabrication approaches with bill of materials and step-by-step assembly instructions.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),

              if (_prototype == null)
                FilledButton.icon(
                  onPressed: _isLoadingPrototype ? null : _generatePrototype,
                  icon: const Icon(Icons.build),
                  label: const Text('Generate Prototype Plan'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: _prototype!.markdown));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarkdownBody(
                  data: _prototype!.markdown,
                  selectable: true,
                ),
              ],

              const SizedBox(height: 16),
              const DisclaimerBanner(),
            ],
          ),
        ),
        if (_isLoadingPrototype)
          const LoadingOverlay(message: 'Generating prototype plan...'),
      ],
    );
  }

  Future<void> _generatePatentDraft() async {
    setState(() => _isLoadingPatent = true);
    try {
      final result = await ApiClient.instance.generatePatentDraft(
        productText: widget.productText,
        variant: widget.variant,
        spec: widget.spec,
        hits: widget.hits,
      );
      if (mounted) {
        setState(() => _patentDraft = result);
        _saveToSession(patentDraft: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPatent = false);
    }
  }

  Future<void> _generatePrototype() async {
    setState(() => _isLoadingPrototype = true);
    try {
      final result = await ApiClient.instance.generatePrototype(
        productText: widget.productText,
        variant: widget.variant,
        spec: widget.spec,
      );
      if (mounted) {
        setState(() => _prototype = result);
        _saveToSession(prototype: result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPrototype = false);
    }
  }

  void _saveToSession(
      {ProvisionalPatentResponse? patentDraft,
      PrototypingResponse? prototype}) {
    if (widget.sessionId == null) return;
    final updates = <String, dynamic>{};
    if (patentDraft != null) {
      updates['patent_draft_json'] = patentDraft.toJson();
    }
    if (prototype != null) {
      updates['prototype_json'] = prototype.toJson();
    }
    // Fire and forget
    ApiClient.instance
        .updateSession(widget.sessionId!, updates)
        .catchError((_) {});
  }
}
