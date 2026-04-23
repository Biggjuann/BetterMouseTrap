import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_analysis.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/whiskers_widgets.dart';
import 'provisional_patent_screen.dart';
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

class _PriorArtScreenState extends State<PriorArtScreen> {
  bool _isLoading = false;
  String? _sourceFilter;

  PatentAnalysisResponse get _a => widget.analysisResponse;

  bool get _canBuildThis {
    if (_a.hits.isEmpty) return true;
    return _a.priorArtSummary.overallRisk != 'high';
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'low': return AppColors.success;
      case 'medium': return AppColors.warn;
      case 'high': return AppColors.danger;
      default: return AppColors.inkSoft;
    }
  }

  String _riskLabel(String level) {
    switch (level) {
      case 'low': return 'Clear Skies';
      case 'medium': return 'Crowded Field';
      case 'high': return 'Heavy Traffic';
      default: return level;
    }
  }

  Color _riskBg(String level) {
    switch (level) {
      case 'low': return AppColors.mintBg;
      case 'medium': return AppColors.sunBg;
      case 'high': return AppColors.peachBg;
      default: return AppColors.lavLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        14, 10, 14, 10),
                    child: Row(
                      children: [
                        IconBtn(
                            icon: Icons.arrow_back_rounded,
                            onPressed: () =>
                                Navigator.pop(context)),
                        const Spacer(),
                        Text('Prior Art',
                            style: AppText.sectionTitle),
                        const Spacer(),
                        IconBtn(
                            icon: Icons.ios_share_rounded,
                            onPressed: () {}),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero verdict card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 8, 20, 16),
                  child: WCard(
                    gradient: LinearGradient(
                      colors: [
                        _riskBg(_a.priorArtSummary.overallRisk)
                            .withValues(alpha: 0.6),
                        _riskBg(
                            _a.priorArtSummary.overallRisk),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Mascot(
                                pose: MascotPose.detective,
                                size: 48),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Prior Art Verdict',
                                    style: AppText.caption),
                                Text(
                                  _riskLabel(_a.priorArtSummary
                                      .overallRisk),
                                  style: AppText.display2.copyWith(
                                    color: _riskColor(_a
                                        .priorArtSummary
                                        .overallRisk),
                                    fontSize: 20,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Pill(
                              'Confidence: ${_a.confidence.toUpperCase()}',
                              bg: AppColors.card,
                              fg: AppColors.inkSoft,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _a.priorArtSummary.narrative,
                          style: AppText.body
                              .copyWith(height: 1.55),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Status summary row
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'High Match',
                          count: _a.hits
                              .where((h) => h.score >= 70)
                              .length,
                          bg: AppColors.peachBg,
                          fg: AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Possible',
                          count: _a.hits
                              .where((h) =>
                                  h.score >= 40 && h.score < 70)
                              .length,
                          bg: AppColors.sunBg,
                          fg: AppColors.warn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatCard(
                          label: 'Low Match',
                          count: _a.hits
                              .where((h) => h.score < 40)
                              .length,
                          bg: AppColors.mintBg,
                          fg: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Key findings
              if (_a.priorArtSummary.keyFindings.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 0, 20, 16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          'What We Saw',
                          action:
                              '${_a.priorArtSummary.keyFindings.length} notes',
                        ),
                        WCard(
                          child: Column(
                            children: _a
                                .priorArtSummary.keyFindings
                                .asMap()
                                .entries
                                .map((e) => Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              bottom: 10),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 22,
                                            decoration: BoxDecoration(
                                              color: AppColors
                                                  .lavLight,
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                          AppRadius
                                                              .sm),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '${e.key + 1}',
                                                style: AppText
                                                    .tiny
                                                    .copyWith(
                                                        color: AppColors
                                                            .lavDark,
                                                        fontWeight:
                                                            FontWeight
                                                                .w700),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width: 10),
                                          Expanded(
                                            child: Text(
                                                e.value,
                                                style: AppText
                                                    .body
                                                    .copyWith(
                                                        height:
                                                            1.5)),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Search coverage
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const SectionHeader('Ground We Covered'),
                      WCard(
                        child: Column(
                          children: [
                            _metaRow(
                                'Queries executed',
                                '${_a.searchMetadata.totalQueriesRun}'),
                            _metaRow(
                                'Keyword matches',
                                '${_a.searchMetadata.keywordHits}'),
                            _metaRow('CPC matches',
                                '${_a.searchMetadata.cpcHits}'),
                            if (_a.searchMetadata.citationHits >
                                0)
                              _metaRow(
                                  'Citation matches',
                                  '${_a.searchMetadata.citationHits}'),
                            _metaRow(
                                'Duplicates removed',
                                '${_a.searchMetadata.duplicatesRemoved}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Prior art results
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        'Specimens on the Shelf',
                        action: '${_a.hits.length} ref.',
                      ),
                      _buildPhaseFilters(),
                      const SizedBox(height: 10),
                      if (_filteredHits.isEmpty)
                        _emptyField()
                      else
                        ..._filteredHits
                            .asMap()
                            .entries
                            .map((e) => Padding(
                                  padding: const EdgeInsets
                                      .only(bottom: 10),
                                  child: _SpecimenCard(
                                    index: e.key + 1,
                                    hit: e.value,
                                  ),
                                )),
                    ],
                  ),
                ),
              ),

              // Analysis blocks
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: _buildAnalysis(),
                ),
              ),

              // Strategy block
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: _buildStrategy(),
                ),
              ),

              // Invention analysis
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 16),
                  child: _buildInventionAnalysis(),
                ),
              ),

              // Disclaimer
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 0, 20, 8),
                  child: WCard(
                    color: AppColors.lavLight,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.lavDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_a.disclaimer,
                              style: AppText.caption),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // CTAs
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 8, 20, 16),
                  child: Column(
                    children: [
                      PrimaryBtn(
                        label: 'Export Full Analysis',
                        trailing: Icons.arrow_downward_rounded,
                        loading: _isLoading,
                        onPressed:
                            _isLoading ? null : _exportOnePager,
                      ),
                      if (_canBuildThis) ...[
                        const SizedBox(height: 10),
                        SoftBtn(
                          label: 'Draft the Application',
                          icon: Icons.edit_note_rounded,
                          bg: AppColors.mintBg,
                          fg: AppColors.success,
                          onPressed: _isLoading
                              ? null
                              : _navigateToBuildThis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 48)),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(
                message: 'Putting together your one-pager…'),
        ],
      ),
    );
  }

  List<EnhancedPatentHit> get _filteredHits {
    if (_sourceFilter == null) return _a.hits;
    return _a.hits
        .where((h) => h.sourcePhase == _sourceFilter)
        .toList();
  }

  Widget _buildPhaseFilters() {
    final phases =
        _a.hits.map((h) => h.sourcePhase).toSet().toList()
          ..sort();
    if (phases.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          _PhaseChip(
            label: 'All · ${_a.hits.length}',
            active: _sourceFilter == null,
            onTap: () => setState(() => _sourceFilter = null),
          ),
          ...phases.map((p) {
            final n =
                _a.hits.where((h) => h.sourcePhase == p).length;
            return _PhaseChip(
              label: '${_phaseLabel(p)} · $n',
              active: _sourceFilter == p,
              onTap: () =>
                  setState(() => _sourceFilter = p),
            );
          }),
        ],
      ),
    );
  }

  String _phaseLabel(String p) {
    switch (p) {
      case 'keyword': return 'Keyword';
      case 'cpc': return 'CPC';
      case 'citation': return 'Citation';
      default: return p;
    }
  }

  Widget _emptyField() {
    return WCard(
      color: AppColors.mintBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Mascot(
                  pose: MascotPose.detective, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A clean shelf!',
                        style: AppText.bodyBold
                            .copyWith(color: AppColors.success)),
                    Text(
                      'No references matched. The field looks open.',
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: AppText.body)),
          Text(value, style: AppText.bodyBold),
        ],
      ),
    );
  }

  Widget _buildAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('How We Read It'),
        _AssessmentCard(
          label: 'Novelty',
          question: 'Is it new?',
          riskLevel: _a.noveltyAssessment.riskLevel,
          summary: _a.noveltyAssessment.summary,
          riskColor: _riskColor,
          riskLabel: _riskLabel,
        ),
        const SizedBox(height: 10),
        _AssessmentCard(
          label: 'Non-Obviousness',
          question: 'Is the leap real?',
          riskLevel: _a.obviousnessAssessment.riskLevel,
          summary: _a.obviousnessAssessment.summary,
          riskColor: _riskColor,
          riskLabel: _riskLabel,
        ),
        if (_a.eligibilityNote.applies) ...[
          const SizedBox(height: 10),
          _AssessmentCard(
            label: 'Eligibility §101',
            question:
                'Is it the kind of thing the office grants?',
            riskLevel: 'medium',
            summary: _a.eligibilityNote.summary,
            riskColor: _riskColor,
            riskLabel: _riskLabel,
          ),
        ],
      ],
    );
  }

  Widget _buildStrategy() {
    final strategy = _a.claimStrategy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('The Move'),
        WCard(
          color: AppColors.sunBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Recommended Filing',
                  style: AppText.caption
                      .copyWith(color: AppColors.warn)),
              const SizedBox(height: 6),
              Text(strategy.filingLabel,
                  style: AppText.display3),
              const SizedBox(height: 10),
              Text(strategy.rationale,
                  style: AppText.body
                      .copyWith(height: 1.55)),
            ],
          ),
        ),
        if (strategy.riskAreas.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Watch for', style: AppText.sectionTitle),
          const SizedBox(height: 8),
          ...strategy.riskAreas.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding:
                          EdgeInsets.only(top: 4, right: 8),
                      child: Icon(
                          Icons.warning_amber_rounded,
                          size: 13,
                          color: AppColors.warn),
                    ),
                    Expanded(
                      child: Text(r,
                          style: AppText.body
                              .copyWith(height: 1.5)),
                    ),
                  ],
                ),
              )),
        ],
        if (strategy.suggestedIndependentClaims.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('Draft Claims', style: AppText.sectionTitle),
          const SizedBox(height: 8),
          ...strategy.suggestedIndependentClaims
              .asMap()
              .entries
              .map((e) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 10),
                    child: WCard(
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Pill('${e.key + 1}'),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(e.value,
                                style: AppText.body
                                    .copyWith(
                                        fontStyle: FontStyle
                                            .italic,
                                        height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                  )),
        ],
      ],
    );
  }

  Widget _buildInventionAnalysis() {
    final inv = _a.inventionAnalysis;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('How We Read the Idea'),
        WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Core concept',
                  style: AppText.caption),
              const SizedBox(height: 4),
              Text(inv.coreConcept,
                  style: AppText.body
                      .copyWith(height: 1.6)),
              if (inv.essentialElements.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text('Essential elements',
                    style: AppText.caption),
                const SizedBox(height: 6),
                ...inv.essentialElements
                    .asMap()
                    .entries
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(
                              bottom: 6),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Pill('${e.key + 1}',
                                  fontSize: 10),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(e.value,
                                    style: AppText.body
                                        .copyWith(
                                            height: 1.5)),
                              ),
                            ],
                          ),
                        )),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToBuildThis() {
    final patentHits = _a.hits
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
        builder: (_) => ProvisionalPatentScreen(
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
      final patentHits = _a.hits
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
          builder: (_) =>
              ExportScreen(exportResponse: response),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Stat card (high/possible/low counts) ────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color bg;
  final Color fg;
  const _StatCard(
      {required this.label,
      required this.count,
      required this.bg,
      required this.fg});

  @override
  Widget build(BuildContext context) {
    return WCard(
      color: bg,
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 10),
      child: Column(
        children: [
          Text('$count',
              style: AppText.display2.copyWith(
                  color: fg, fontSize: 24)),
          Text(label,
              style: AppText.tiny.copyWith(color: fg),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Phase filter chip ────────────────────────────────────────────────
class _PhaseChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PhaseChip(
      {required this.label,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.lav : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
              color: active
                  ? AppColors.lav
                  : AppColors.hairline),
        ),
        child: Text(label,
            style: AppText.caption.copyWith(
                color: active
                    ? Colors.white
                    : AppColors.inkSoft,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ── Specimen card ─────────────────────────────────────────────────────
class _SpecimenCard extends StatefulWidget {
  final int index;
  final EnhancedPatentHit hit;
  const _SpecimenCard(
      {required this.index, required this.hit});

  @override
  State<_SpecimenCard> createState() => _SpecimenCardState();
}

class _SpecimenCardState extends State<_SpecimenCard> {
  bool _open = false;

  Color get _scoreColor {
    final s = widget.hit.scorePercent;
    if (s >= 70) return AppColors.danger;
    if (s >= 40) return AppColors.warn;
    return AppColors.success;
  }

  Color get _scoreBg {
    final s = widget.hit.scorePercent;
    if (s >= 70) return AppColors.peachBg;
    if (s >= 40) return AppColors.sunBg;
    return AppColors.mintBg;
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    return WCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: _scoreBg,
                        borderRadius: BorderRadius.circular(
                            AppRadius.sm)),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          '${h.scorePercent}',
                          style: AppText.bodyBold.copyWith(
                              color: _scoreColor,
                              fontSize: 13),
                        ),
                        Text('%',
                            style: AppText.tiny
                                .copyWith(color: _scoreColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(h.title,
                            style: AppText.bodyBold,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(h.patentId,
                                style: AppText.tiny),
                            if (h.assignee != null)
                              Text('· ${h.assignee}',
                                  style: AppText.tiny),
                            if (h.date != null)
                              Text('· ${h.date}',
                                  style: AppText.tiny),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                      height: 1,
                      color: AppColors.hairline),
                  const SizedBox(height: 12),
                  Text('Why it\'s similar',
                      style: AppText.caption.copyWith(
                          color: AppColors.lavDark)),
                  const SizedBox(height: 6),
                  Text(h.whySimilar,
                      style: AppText.body
                          .copyWith(height: 1.6)),
                  if (h.abstract_.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('Abstract',
                        style: AppText.caption.copyWith(
                            color: AppColors.lavDark)),
                    const SizedBox(height: 4),
                    Text(h.abstract_,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.5)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Assessment card ──────────────────────────────────────────────────
class _AssessmentCard extends StatelessWidget {
  final String label;
  final String question;
  final String riskLevel;
  final String summary;
  final Color Function(String) riskColor;
  final String Function(String) riskLabel;

  const _AssessmentCard({
    required this.label,
    required this.question,
    required this.riskLevel,
    required this.summary,
    required this.riskColor,
    required this.riskLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = riskColor(riskLevel);
    return WCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: AppText.sectionTitle),
              ),
              Pill(riskLabel(riskLevel),
                  bg: c.withValues(alpha: 0.15),
                  fg: c),
            ],
          ),
          const SizedBox(height: 8),
          Text(question,
              style: AppText.bodyBold.copyWith(
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),
          Text(summary,
              style: AppText.body.copyWith(height: 1.6)),
        ],
      ),
    );
  }
}
