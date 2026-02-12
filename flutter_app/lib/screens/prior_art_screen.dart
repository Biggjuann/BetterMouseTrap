import 'package:flutter/material.dart';
import 'dart:math' as math;

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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          Column(
            children: [
              // Stitch nav bar — sticky with primary border
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cream.withValues(alpha: 0.8),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      // Top row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 28),
                              color: AppColors.primary,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'Patent Analysis',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share, size: 22),
                              color: AppColors.primary,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      // Tab bar — Stitch scroll tabs
                      TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.base,
                        ),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'Prior Art'),
                          Tab(text: 'Analysis'),
                          Tab(text: 'Strategy'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildPriorArtTab(),
                    _buildAnalysisTab(),
                    _buildStrategyTab(),
                  ],
                ),
              ),
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
        // Risk summary card — Stitch: circular ring + label
        _RiskHeroCard(
          riskLevel: summary.overallRisk,
          narrative: summary.narrative,
          confidence: _analysis.confidence,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Key findings
        if (summary.keyFindings.isNotEmpty) ...[
          _SectionHeader(title: 'Key Findings'),
          const SizedBox(height: AppSpacing.md),
          ...summary.keyFindings.map((f) => _FindingCard(finding: f)),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Search stats
        _SectionHeader(title: 'Search Coverage'),
        const SizedBox(height: AppSpacing.md),
        _StitchCard(
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

        const DisclaimerBanner(),
        const SizedBox(height: AppSpacing.lg),

        // Action buttons — Stitch fixed bottom style
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
                  label: '${_sourcePhaseLabel(p)} ($count)',
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
        _AssessmentCard(
          title: 'Novelty Assessment',
          icon: Icons.verified,
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

        _AssessmentCard(
          title: 'Non-Obviousness',
          icon: Icons.psychology,
          riskLevel: _analysis.obviousnessAssessment.riskLevel,
          summary: _analysis.obviousnessAssessment.summary,
          details: [
            if (_analysis.obviousnessAssessment.combinationRefs.isNotEmpty)
              'Could be combined: ${_analysis.obviousnessAssessment.combinationRefs.join(', ')}',
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        if (_analysis.eligibilityNote.applies) ...[
          _AssessmentCard(
            title: 'Patent Eligibility (\u00A7101)',
            icon: Icons.gavel,
            riskLevel: 'medium',
            summary: _analysis.eligibilityNote.summary,
            details: [],
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Claim strategy
        _SectionHeader(title: 'Claim Strategy'),
        const SizedBox(height: AppSpacing.md),
        _StitchCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FilingBadge(filing: _analysis.claimStrategy.recommendedFiling),
              const SizedBox(height: AppSpacing.md),
              Text(
                _analysis.claimStrategy.rationale,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                      color: AppColors.ink,
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
                        const Icon(Icons.warning_amber_rounded,
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
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
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
        _SectionHeader(title: 'Core Concept'),
        const SizedBox(height: AppSpacing.md),
        _StitchCard(
          child: Text(
            inv.coreConcept,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.ink,
                ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionHeader(title: 'Essential Elements'),
        const SizedBox(height: AppSpacing.md),
        _StitchCard(
          child: Column(
            children: inv.essentialElements
                .map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle,
                              size: 18, color: AppColors.teal),
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
        const SizedBox(height: AppSpacing.lg),

        // CPC classifications — Stitch style chips
        if (inv.cpcCodes.isNotEmpty) ...[
          _SectionHeader(title: 'CPC Classifications'),
          const SizedBox(height: AppSpacing.md),
          _StitchCard(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: inv.cpcCodes
                  .map((cpc) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardWhite,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                          ),
                          boxShadow: AppShadows.card,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cpc.code,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cpc.description,
                              style: TextStyle(
                                color: AppColors.slateLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Search strategies
        if (inv.searchStrategies.isNotEmpty) ...[
          _SectionHeader(title: 'Search Queries Used'),
          const SizedBox(height: AppSpacing.md),
          _StitchCard(
            child: Column(
              children: inv.searchStrategies
                  .map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.cream,
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
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
          const SizedBox(height: AppSpacing.lg),
        ],

        // Alternative implementations
        if (inv.alternativeImplementations.isNotEmpty) ...[
          _SectionHeader(title: 'Alternative Approaches'),
          const SizedBox(height: AppSpacing.md),
          _StitchCard(
            child: Column(
              children: inv.alternativeImplementations
                  .map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right_rounded,
                                size: 18, color: AppColors.slateLight),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(a,
                                  style: Theme.of(context).textTheme.bodySmall),
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
        border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
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

  String _sourcePhaseLabel(String phase) {
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

// Section header — Stitch: uppercase bold tracking-widest
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: AppColors.slateLight,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }
}

// Generic Stitch card container
class _StitchCard extends StatelessWidget {
  final Widget child;
  const _StitchCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        boxShadow: AppShadows.card,
      ),
      child: child,
    );
  }
}

// Stitch risk hero card with SVG-like circular ring
class _RiskHeroCard extends StatelessWidget {
  final String riskLevel;
  final String narrative;
  final String confidence;

  const _RiskHeroCard({
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

  double get _riskPercent {
    switch (riskLevel) {
      case 'low':
        return 0.25;
      case 'medium':
        return 0.62;
      case 'high':
        return 0.85;
      default:
        return 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: labels
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RISK ASSESSMENT',
                      style: TextStyle(
                        color: AppColors.slateLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _riskLabel,
                      style: TextStyle(
                        color: _riskColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: circular ring — Stitch style
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: _riskPercent,
                    color: _riskColor,
                    trackColor: AppColors.cream,
                  ),
                  child: Center(
                    child: Text(
                      '${(_riskPercent * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            narrative,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: AppColors.ink,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Tags
          Wrap(
            spacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _riskColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'NEEDS REVIEW',
                  style: TextStyle(
                    color: _riskColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              ConfidenceBadge(level: confidence),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom ring painter for the risk percentage
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 8.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// Finding card — Stitch: icon + content
class _FindingCard extends StatelessWidget {
  final String finding;
  const _FindingCard({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.base),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, color: AppColors.teal, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                finding,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
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
        return 'LOW RISK';
      case 'medium':
        return 'MEDIUM RISK';
      case 'high':
        return 'HIGH RISK';
      default:
        return riskLevel.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
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
                ),
                child: Text(
                  _label,
                  style: TextStyle(
                    color: _color,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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
                  color: AppColors.ink,
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
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.stone,
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
        return AppColors.primary;
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
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.primary,
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
      child: _StitchCard(
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
                            color: AppColors.primary,
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
                                  color: AppColors.primary,
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
                        color: AppColors.cream,
                        borderRadius:
                            BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
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
                                          color: AppColors.primary
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          c,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
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
                                color: AppColors.primary.withValues(alpha: 0.1),
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
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.slateLight),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: AppColors.slateLight,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: AppColors.primary,
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
        // Export CTA — Stitch primary button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: AppShadows.button,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: FilledButton(
              onPressed: isLoading ? null : onExport,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.picture_as_pdf, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('Export Full Analysis'),
                ],
              ),
            ),
          ),
        ),

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
                  Icon(Icons.gavel, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text("Let's Build This!"),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
