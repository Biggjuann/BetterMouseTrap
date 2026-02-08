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
            Tab(icon: Icon(Icons.shield_rounded), text: 'Protect It'),
            Tab(icon: Icon(Icons.construction_rounded), text: 'Build It'),
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
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.warmWhite, Color(0xFFFFF9F0)],
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: const Color(0xFF7B1FA2).withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Protect Your Idea',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkCharcoal,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'When you create something unique, you have to protect it.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.warmGray,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_patentDraft == null)
                _buildCTAButton(
                  icon: Icons.description_rounded,
                  label: 'Draft My Patent',
                  gradientColors: [const Color(0xFF7B1FA2), const Color(0xFF9C27B0)],
                  onTap: _isLoadingPatent ? null : _generatePatentDraft,
                )
              else ...[
                _copyBar(() {
                  Clipboard.setData(ClipboardData(text: _patentDraft!.markdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.lightWarmGray.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: _patentDraft!.markdown,
                    selectable: true,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.base),
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
        // Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.warmWhite, Color(0xFFFFF9F0)],
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.construction, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Build Your Prototype',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkCharcoal,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stay lean and mean! Get a practical build plan.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.warmGray,
                                  height: 1.4,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_prototype == null)
                _buildCTAButton(
                  icon: Icons.build_rounded,
                  label: 'Show Me How to Build It',
                  gradientColors: [const Color(0xFF2E7D32), const Color(0xFF43A047)],
                  onTap: _isLoadingPrototype ? null : _generatePrototype,
                )
              else ...[
                _copyBar(() {
                  Clipboard.setData(ClipboardData(text: _prototype!.markdown));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Copied to clipboard!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: AppColors.lightWarmGray.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: _prototype!.markdown,
                    selectable: true,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.base),
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

  Widget _buildCTAButton({
    required IconData icon,
    required String label,
    required List<Color> gradientColors,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.base,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _copyBar(VoidCallback onCopy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.primaryAmber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: TextButton.icon(
            onPressed: onCopy,
            icon: Icon(Icons.copy_rounded, size: 16, color: AppColors.primaryAmber),
            label: Text(
              'Copy',
              style: TextStyle(
                color: AppColors.primaryAmber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
    // Fire and forget
    ApiClient.instance
        .updateSession(widget.sessionId!, updates)
        .catchError((_) {});
  }
}
