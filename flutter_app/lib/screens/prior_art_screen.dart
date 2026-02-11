import 'package:flutter/material.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_analysis.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/confidence_badge.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/score_badge.dart';
import 'build_this_screen.dart';
import 'export_screen.dart';

class PriorArtScreen extends StatefulWidget {
  final ProductInput product;
  final IdeaVariant variant;
  final IdeaSpec spec;
  final PatentAnalysisResponse analysisResponse;
  final String? sessionId;

  const PriorArtScreen({
    super.key,
    required this.product,
    required this.variant,
    required this.spec,
    required this.analysisResponse,
    this.sessionId,
  });

  @override
  State<PriorArtScreen> createState() => _PriorArtScreenState();
}

class _PriorArtScreenState extends State<PriorArtScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isLoading = false;
  String? _selectedSourceFilter;

  PatentAnalysisResponse get _analysis => widget.analysisResponse;

  bool get _canBuildThis {
    if (_analysis.hits.isEmpty) return true;
    return _analysis.priorArtSummary.overallRisk != 'high';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Patent Analysis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Prior Art'),
            Tab(text: 'Analysis'),
            Tab(text: 'Strategy'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildPriorArtTab(),
              _buildAnalysisTab(),
              _buildStrategyTab(),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(
                message: 'Putting together your one-pager...'),
        ],
      ),
    );
  }

  // ── Tab 1: Overview ─────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final summary = _analysis.priorArtSummary;
    final meta = _analysis.searchMetadata;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Risk level hero card
        _RiskCard(
          riskLevel: summary.overallRisk,
          narrative: summary.narrative,
          confidence: _analysis.confidence,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Search stats
        _SectionCard(
          icon: Icons.analytics_outlined,
          color: AppColors.teal,
          title: 'Search Coverage',
          child: Column(
            children: [
              _StatRow('Queries executed', '${meta.totalQueriesRun}'),
              _StatRow('Keyword matches', '${meta.keywordHits}'),
              _StatRow('CPC matches', '${meta.cpcHits}'),
              if (meta.citationHits > 0)
                _StatRow('Citation matches', '${meta.citationHits}'),
              _StatRow('Duplicates removed', '${meta.duplicatesRemoved}'),
              _StatRow('Phases completed', meta.phasesCompleted.join(', ')),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Key findings
        if (summary.keyFindings.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.lightbulb_outline,
            color: AppColors.amber,
            title: 'Key Findings',
            child: Column(
              children: summary.keyFindings
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.amber,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(f,
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        const DisclaimerBanner(),
        const SizedBox(height: AppSpacing.lg),

        // Action buttons
        _ActionButtons(
          isLoading: _isLoading,
          canBuildThis: _canBuildThis,
          onExport: _exportOnePager,
          onBuildThis: _navigateToBuildThis,
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Tab 2: Prior Art Results ────────────────────────────────────────

  Widget _buildPriorArtTab() {
    final allHits = _analysis.hits;
    final phases =
        allHits.map((h) => h.sourcePhase).toSet().toList()..sort();

    // Filter hits
    final filteredHits = _selectedSourceFilter == null
        ? allHits
        : allHits
            .where((h) => h.sourcePhase == _selectedSourceFilter)
            .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Filter chips
        if (phases.length > 1) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All (${allHits.length})',
                selected: _selectedSourceFilter == null,
                onTap: () =>
                    setState(() => _selectedSourceFilter = null),
              ),
              ...phases.map((p) {
                final count =
                    allHits.where((h) => h.sourcePhase == p).length;
                return _FilterChip(
                  label:
                      '${_sourcePhasLabel(p)} ($count)',
                  selected: _selectedSourceFilter == p,
                  onTap: () =>
                      setState(() => _selectedSourceFilter = p),
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Confidence row
        Row(
          children: [
            Text(
              'Search Confidence',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            ConfidenceBadge(level: _analysis.confidence),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Patent hits
        if (filteredHits.isEmpty)
          _emptyState()
        else
          ...filteredHits.map((hit) => _EnhancedPatentHitCard(hit: hit)),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Tab 3: Analysis ─────────────────────────────────────────────────

  Widget _buildAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Novelty
        _AssessmentCard(
          title: 'Novelty Assessment',
          icon: Icons.new_releases_outlined,
          riskLevel: _analysis.noveltyAssessment.riskLevel,
          summary: _analysis.noveltyAssessment.summary,
          details: [
            if (_analysis.noveltyAssessment.closestReference != null)
              'Closest reference: ${_analysis.noveltyAssessment.closestReference}',
            if (_analysis.noveltyAssessment.missingElements.isNotEmpty)
              'Elements NOT found in prior art:\n${_analysis.noveltyAssessment.missingElements.map((e) => '  - $e').join('\n')}',
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Obviousness
        _AssessmentCard(
          title: 'Non-Obviousness',
          icon: Icons.psychology_outlined,
          riskLevel: _analysis.obviousnessAssessment.riskLevel,
          summary: _analysis.obviousnessAssessment.summary,
          details: [
            if (_analysis.obviousnessAssessment.combinationRefs.isNotEmpty)
              'Could be combined: ${_analysis.obviousnessAssessment.combinationRefs.join(', ')}',
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Eligibility
        if (_analysis.eligibilityNote.applies) ...[
          _AssessmentCard(
            title: 'Patent Eligibility (\u00A7101)',
            icon: Icons.gavel_outlined,
            riskLevel: 'medium',
            summary: _analysis.eligibilityNote.summary,
            details: [],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Claim strategy
        _SectionCard(
          icon: Icons.description_outlined,
          color: AppColors.teal,
          title: 'Claim Strategy',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilingBadge(filing: _analysis.claimStrategy.recommendedFiling),
              const SizedBox(height: AppSpacing.md),
              Text(
                _analysis.claimStrategy.rationale,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
              ),
              if (_analysis.claimStrategy.riskAreas.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Risk Areas',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...(_analysis.claimStrategy.riskAreas.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(r,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
              if (_analysis.claimStrategy.suggestedIndependentClaims
                  .isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Suggested Claims',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...(_analysis.claimStrategy.suggestedIndependentClaims
                    .asMap()
                    .entries
                    .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warmWhite,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        const DisclaimerBanner(),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Tab 4: Search Strategy ──────────────────────────────────────────

  Widget _buildStrategyTab() {
    final inv = _analysis.inventionAnalysis;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // Core concept
        _SectionCard(
          icon: Icons.hub_outlined,
          color: AppColors.teal,
          title: 'Core Concept',
          child: Text(
            inv.coreConcept,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Essential elements
        _SectionCard(
          icon: Icons.checklist_outlined,
          color: AppColors.amber,
          title: 'Essential Elements',
          child: Column(
            children: inv.essentialElements
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: AppColors.amber),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(e,
                                style:
                                    Theme.of(context).textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // CPC classifications
        if (inv.cpcCodes.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.category_outlined,
            color: AppColors.coral,
            title: 'CPC Classifications',
            child: Column(
              children: inv.cpcCodes
                  .map((cpc) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.coral.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                cpc.code,
                                style: TextStyle(
                                  color: AppColors.coral,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(cpc.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(cpc.rationale,
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Search strategies
        if (inv.searchStrategies.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.search_rounded,
            color: AppColors.success,
            title: 'Search Queries Used',
            child: Column(
              children: inv.searchStrategies
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.warmWhite,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border:
                                Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '"${s.query}"',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ApproachChip(approach: s.approach),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Alternative implementations
        if (inv.alternativeImplementations.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.alt_route_outlined,
            color: AppColors.stone,
            title: 'Alternative Approaches Considered',
            child: Column(
              children: inv.alternativeImplementations
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right_rounded,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(a,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                color: AppColors.success, size: 28),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'The field is wide open!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No matching patents found — your idea could be a real hero.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _sourcePhasLabel(String phase) {
    switch (phase) {
      case 'keyword':
        return 'Keyword';
      case 'cpc':
        return 'CPC';
      case 'citation':
        return 'Citation';
      default:
        return phase;
    }
  }

  void _navigateToBuildThis() {
    // Convert enhanced hits to PatentHit for backward compat
    final patentHits = _analysis.hits
        .map((h) => PatentHit(
              patentId: h.patentId,
              title: h.title,
              abstract_: h.abstract_,
              assignee: h.assignee,
              date: h.date,
              score: h.score,
              whySimilar: h.whySimilar,
            ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BuildThisScreen(
          productText: widget.product.text,
          variant: widget.variant,
          spec: widget.spec,
          hits: patentHits,
          sessionId: widget.sessionId,
        ),
      ),
    );
  }

  Future<void> _exportOnePager() async {
    setState(() => _isLoading = true);
    try {
      // Convert enhanced hits to PatentHit for export
      final patentHits = _analysis.hits
          .map((h) => PatentHit(
                patentId: h.patentId,
                title: h.title,
                abstract_: h.abstract_,
                assignee: h.assignee,
                date: h.date,
                score: h.score,
                whySimilar: h.whySimilar,
              ))
          .toList();

      final response = await ApiClient.instance.exportOnePager(
        product: widget.product,
        variant: widget.variant,
        spec: widget.spec,
        hits: patentHits,
      );

      if (widget.sessionId != null) {
        ApiClient.instance.updateSession(widget.sessionId!, {
          'export_markdown': response.markdown,
          'export_plain_text': response.plainText,
          'status': 'exported',
        }).catchError((_) {});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportScreen(exportResponse: response),
        ),
      );
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
}

// ── Reusable widgets ──────────────────────────────────────────────────

class _RiskCard extends StatelessWidget {
  final String riskLevel;
  final String narrative;
  final String confidence;

  const _RiskCard({
    required this.riskLevel,
    required this.narrative,
    required this.confidence,
  });

  Color get _riskColor {
    switch (riskLevel) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.stone;
    }
  }

  String get _riskLabel {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return riskLevel;
    }
  }

  IconData get _riskIcon {
    switch (riskLevel) {
      case 'low':
        return Icons.check_circle_outline;
      case 'medium':
        return Icons.info_outline;
      case 'high':
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _riskColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _riskColor.withValues(alpha: 0.2)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_riskIcon, color: _riskColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Prior Art Risk',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _riskColor.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        _riskLabel,
                        style: TextStyle(
                          color: _riskColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ConfidenceBadge(level: confidence),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            narrative,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String riskLevel;
  final String summary;
  final List<String> details;

  const _AssessmentCard({
    required this.title,
    required this.icon,
    required this.riskLevel,
    required this.summary,
    required this.details,
  });

  Color get _color {
    switch (riskLevel) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.stone;
    }
  }

  String get _label {
    switch (riskLevel) {
      case 'low':
        return 'Low Risk';
      case 'medium':
        return 'Medium Risk';
      case 'high':
        return 'High Risk';
      default:
        return riskLevel;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, color: _color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border:
                      Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            ...details.map((d) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    d,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.1)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.teal : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.teal : null,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilingBadge extends StatelessWidget {
  final String filing;
  const _FilingBadge({required this.filing});

  String get _label {
    switch (filing) {
      case 'provisional':
        return 'File Provisional Patent';
      case 'non_provisional':
        return 'File Full Patent Application';
      case 'design_patent':
        return 'Consider Design Patent';
      case 'defer':
        return 'Defer — More Research Needed';
      case 'abandon':
        return 'Not Recommended to File';
      default:
        return filing;
    }
  }

  Color get _color {
    switch (filing) {
      case 'provisional':
        return AppColors.teal;
      case 'non_provisional':
        return AppColors.success;
      case 'design_patent':
        return AppColors.amber;
      case 'defer':
        return AppColors.warning;
      case 'abandon':
        return AppColors.error;
      default:
        return AppColors.stone;
    }
  }

  IconData get _icon {
    switch (filing) {
      case 'provisional':
        return Icons.description_outlined;
      case 'non_provisional':
        return Icons.verified_outlined;
      case 'design_patent':
        return Icons.design_services_outlined;
      case 'defer':
        return Icons.pause_circle_outline;
      case 'abandon':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 18, color: _color),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApproachChip extends StatelessWidget {
  final String approach;
  const _ApproachChip({required this.approach});

  String get _label {
    switch (approach) {
      case 'function_words':
        return 'Function';
      case 'technical_structure':
        return 'Structure';
      case 'use_case':
        return 'Use Case';
      case 'synonyms':
        return 'Synonyms';
      default:
        return approach;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EnhancedPatentHitCard extends StatefulWidget {
  final EnhancedPatentHit hit;
  const _EnhancedPatentHitCard({required this.hit});

  @override
  State<_EnhancedPatentHitCard> createState() =>
      _EnhancedPatentHitCardState();
}

class _EnhancedPatentHitCardState extends State<_EnhancedPatentHitCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final hit = widget.hit;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.card,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScoreBadge(score: hit.score),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          hit.patentId,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        _SourcePhaseChip(phase: hit.sourcePhase),
                      ],
                    ),
                    if (hit.assignee != null || hit.date != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: 4,
                        children: [
                          if (hit.assignee != null)
                            _metaChip(
                                Icons.business_rounded, hit.assignee!),
                          if (hit.date != null)
                            _metaChip(
                                Icons.calendar_today_rounded, hit.date!),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Expandable details
                    InkWell(
                      onTap: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              size: 18,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isExpanded
                                  ? 'Hide details'
                                  : 'How it compares',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isExpanded) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.warmWhite,
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                          border:
                              Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hit.whySimilar,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(height: 1.5),
                            ),
                            if (hit.cpcCodes.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: hit.cpcCodes
                                    .take(5)
                                    .map((c) => Container(
                                          padding: const EdgeInsets
                                              .symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.coral
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            c,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.coral,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                            if (hit.abstract_.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Divider(
                                  color: AppColors.borderLight,
                                  height: 1),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                hit.abstract_,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                ),
          ),
        ),
      ],
    );
  }
}

class _SourcePhaseChip extends StatelessWidget {
  final String phase;
  const _SourcePhaseChip({required this.phase});

  String get _label {
    switch (phase) {
      case 'keyword':
        return 'Keyword';
      case 'cpc':
        return 'CPC';
      case 'citation':
        return 'Citation';
      default:
        return phase;
    }
  }

  Color get _color {
    switch (phase) {
      case 'keyword':
        return AppColors.teal;
      case 'cpc':
        return AppColors.coral;
      case 'citation':
        return AppColors.amber;
      default:
        return AppColors.stone;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool isLoading;
  final bool canBuildThis;
  final VoidCallback onExport;
  final VoidCallback onBuildThis;

  const _ActionButtons({
    required this.isLoading,
    required this.canBuildThis,
    required this.onExport,
    required this.onBuildThis,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Export CTA
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: isLoading ? null : onExport,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 20),
                SizedBox(width: AppSpacing.sm),
                Text(
                  'Get your one-pager',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Build This button
        if (canBuildThis) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: isLoading ? null : onBuildThis,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.teal,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch_outlined, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Let\'s Build This!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
