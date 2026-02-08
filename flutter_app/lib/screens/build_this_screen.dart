import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_hit.dart';
import '../models/provisional_patent.dart';
import '../models/prototyping_response.dart';
import '../services/api_client.dart';
import '../theme.dart';
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
        title: const Text('Make It Real'),
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.shield_outlined), text: 'Protect It'),
            Tab(icon: Icon(Icons.construction_outlined), text: 'Build It'),
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
        Container(
          decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protect Your Idea',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When you create something unique, you have to protect it.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_patentDraft == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoadingPatent ? null : _generatePatentDraft,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Draft My Patent',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _copyBar(() {
                  Clipboard.setData(ClipboardData(text: _patentDraft!.markdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: MarkdownBody(
                    data: _patentDraft!.markdown,
                    selectable: true,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              const DisclaimerBanner(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (_isLoadingPatent)
          const LoadingOverlay(message: 'Drafting your patent application...'),
      ],
    );
  }

  Widget _prototypeTab() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.warmWhite,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(Icons.construction_outlined, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build Your Prototype',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stay lean and mean! Get a practical build plan.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_prototype == null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoadingPrototype ? null : _generatePrototype,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.build_outlined, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text(
                          'Show Me How to Build It',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _copyBar(() {
                  Clipboard.setData(ClipboardData(text: _prototype!.markdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.cardWhite,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppShadows.elevated,
                  ),
                  child: MarkdownBody(
                    data: _prototype!.markdown,
                    selectable: true,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              const DisclaimerBanner(),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
        if (_isLoadingPrototype)
          const LoadingOverlay(message: 'Putting together your build plan...'),
      ],
    );
  }

  Widget _copyBar(VoidCallback onCopy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 16),
          label: const Text('Copy'),
        ),
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
    ApiClient.instance
        .updateSession(widget.sessionId!, updates)
        .catchError((_) {});
  }
}
