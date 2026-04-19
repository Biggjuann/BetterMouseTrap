import 'package:flutter/material.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/patent_analysis.dart';
import '../models/patent_hit.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/studio_widgets.dart';
import 'provisional_patent_screen.dart';
import 'export_screen.dart';

// ─────────────────────────────────────────────────────────────────────
// Prior Art — Dossier language
//
// Editorial layout, single vertical scroll. Sections stacked like a
// printed report: file header → verdict → the field → what was read →
// the reasoning → what to do next.
// ─────────────────────────────────────────────────────────────────────

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

  String _stubFileNum() {
    final t = widget.variant.title;
    var h = 0;
    for (final c in t.codeUnits) {
      h = (h * 31 + c) & 0xffff;
    }
    final n = 1000 + (h % 8999);
    return 'PA-$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header bar — file ribbon
              SliverToBoxAdapter(child: _Header(onBack: () => Navigator.pop(context))),

              // Dossier masthead
              SliverToBoxAdapter(child: _Masthead(
                fileNumber: _stubFileNum(),
                title: widget.variant.title,
                riskLevel: _a.priorArtSummary.overallRisk,
              )),

              // Verdict — the pull quote
              SliverToBoxAdapter(child: _VerdictBlock(
                riskLevel: _a.priorArtSummary.overallRisk,
                narrative: _a.priorArtSummary.narrative,
                confidence: _a.confidence,
              )),

              // Key findings
              if (_a.priorArtSummary.keyFindings.isNotEmpty)
                SliverToBoxAdapter(child: _KeyFindingsBlock(
                  findings: _a.priorArtSummary.keyFindings,
                )),

              // The field — search coverage ledger
              SliverToBoxAdapter(child: _LedgerBlock(meta: _a.searchMetadata)),

              // Prior art results
              SliverToBoxAdapter(child: _PriorArtListBlock(
                hits: _a.hits,
                selected: _sourceFilter,
                onSelect: (s) => setState(() => _sourceFilter = s),
                confidence: _a.confidence,
              )),

              // Analysis — novelty, obviousness, eligibility
              SliverToBoxAdapter(child: _AnalysisBlock(a: _a)),

              // Claim strategy
              SliverToBoxAdapter(child: _StrategyBlock(strategy: _a.claimStrategy)),

              // Invention analysis — how we read it
              SliverToBoxAdapter(child: _InventionBlock(inv: _a.inventionAnalysis)),

              // Disclaimer
              SliverToBoxAdapter(child: _DisclaimerBlock(text: _a.disclaimer)),

              // CTAs
              SliverToBoxAdapter(child: _FootActions(
                canBuildThis: _canBuildThis,
                isLoading: _isLoading,
                onExport: _exportOnePager,
                onBuildThis: _navigateToBuildThis,
              )),

              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
          if (_isLoading)
            const LoadingOverlay(message: 'Putting together your one-pager…'),
        ],
      ),
    );
  }

  void _navigateToBuildThis() {
    final patentHits = _a.hits.map((h) => PatentHit(
          patentId: h.patentId,
          title: h.title,
          abstract_: h.abstract_,
          assignee: h.assignee,
          date: h.date,
          score: h.score,
          whySimilar: h.whySimilar,
        )).toList();

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
      final patentHits = _a.hits.map((h) => PatentHit(
            patentId: h.patentId,
            title: h.title,
            abstract_: h.abstract_,
            assignee: h.assignee,
            date: h.date,
            score: h.score,
            whySimilar: h.whySimilar,
          )).toList();

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

// ── Layout helpers ───────────────────────────────────────────────────

const EdgeInsets _pageH = EdgeInsets.symmetric(horizontal: 22);

Color _riskColor(String level) {
  switch (level) {
    case 'low':  return AppColors.success;
    case 'medium': return AppColors.warning;
    case 'high': return AppColors.error;
    default: return AppColors.graphite;
  }
}

String _riskLabel(String level) {
  switch (level) {
    case 'low':  return 'Clear skies';
    case 'medium': return 'Crowded field';
    case 'high': return 'Heavy traffic';
    default: return level;
  }
}

// ── Header ──────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Row(
          children: [
            IconBtn(icon: Icons.arrow_back_rounded, onPressed: onBack),
            const Spacer(),
            Text('THE FIELD REPORT', style: AppText.monoMeta),
            const Spacer(),
            IconBtn(icon: Icons.ios_share_rounded, onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

// ── Masthead: file Nº · title · risk tag ────────────────────────────

class _Masthead extends StatelessWidget {
  final String fileNumber;
  final String title;
  final String riskLevel;

  const _Masthead({
    required this.fileNumber,
    required this.title,
    required this.riskLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(top: 8, bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: _riskColor(riskLevel), shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text('File Nº $fileNumber', style: AppText.monoMeta),
              const SizedBox(width: 10),
              Text('·', style: AppText.monoMeta),
              const SizedBox(width: 10),
              Text('Prior art'.toUpperCase(), style: AppText.monoMeta),
            ],
          ),
          const SizedBox(height: 18),
          Text('The ', style: AppText.display2.copyWith(color: AppColors.mist), maxLines: 1),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: AppText.display1,
                children: [
                  const TextSpan(text: 'field for '),
                  TextSpan(
                    text: _shorten(title),
                    style: AppText.display1.copyWith(fontStyle: FontStyle.italic, color: AppColors.accentInk),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shorten(String s) {
    final words = s.split(' ');
    if (words.length <= 5) return s;
    return '${words.take(5).join(' ')}…';
  }
}

// ── Verdict: big label + narrative as editorial pull quote ──────────

class _VerdictBlock extends StatelessWidget {
  final String riskLevel;
  final String narrative;
  final String confidence;

  const _VerdictBlock({
    required this.riskLevel,
    required this.narrative,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final c = _riskColor(riskLevel);
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: StudioCard(
        background: AppColors.accentSoft,
        border: Border.all(color: Colors.transparent),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Eyebrow('Verdict', color: AppColors.accentInk.withValues(alpha: 0.6)),
                const Spacer(),
                Text('Confidence · ${confidence.toUpperCase()}', style: AppText.monoMeta),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              _riskLabel(riskLevel),
              style: AppText.display2.copyWith(
                fontStyle: FontStyle.italic,
                color: c,
                height: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              narrative,
              style: AppText.bodyLg.copyWith(height: 1.55, color: AppColors.accentInk),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Key findings ─────────────────────────────────────────────────────

class _KeyFindingsBlock extends StatelessWidget {
  final List<String> findings;
  const _KeyFindingsBlock({required this.findings});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'I · Observations',
            title: 'What we saw',
            trailing: '${findings.length} notes',
          ),
          ...List.generate(findings.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${i + 1}'.padLeft(2, '0'),
                    style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                ),
                Expanded(
                  child: Text(findings[i],
                    style: AppText.body.copyWith(height: 1.6)),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Search coverage ledger ──────────────────────────────────────────

class _LedgerBlock extends StatelessWidget {
  final SearchMetadata meta;
  const _LedgerBlock({required this.meta});

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry('Queries executed', '${meta.totalQueriesRun}'),
      MapEntry('Keyword matches', '${meta.keywordHits}'),
      MapEntry('CPC matches', '${meta.cpcHits}'),
      if (meta.citationHits > 0) MapEntry('Citation matches', '${meta.citationHits}'),
      MapEntry('Duplicates removed', '${meta.duplicatesRemoved}'),
      MapEntry('Phases completed', meta.phasesCompleted.join(' · ')),
    ];
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: 'II · The search', title: 'Ground we covered'),
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.rule)),
            ),
            child: Column(
              children: rows.map((r) => _LedgerRow(label: r.key, value: r.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final String label;
  final String value;
  const _LedgerRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.rule)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppText.body.copyWith(color: AppColors.graphite))),
          Text(value, style: AppText.monoValue),
        ],
      ),
    );
  }
}

// ── Prior art list ──────────────────────────────────────────────────

class _PriorArtListBlock extends StatelessWidget {
  final List<EnhancedPatentHit> hits;
  final String? selected;
  final ValueChanged<String?> onSelect;
  final String confidence;

  const _PriorArtListBlock({
    required this.hits,
    required this.selected,
    required this.onSelect,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    final phases = hits.map((h) => h.sourcePhase).toSet().toList()..sort();
    final filtered = selected == null ? hits : hits.where((h) => h.sourcePhase == selected).toList();

    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'III · What we read',
            title: 'Specimens on the shelf',
            trailing: '${hits.length} ref.',
          ),

          if (phases.length > 1) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PhaseChip(
                  label: 'All · ${hits.length}',
                  active: selected == null,
                  onTap: () => onSelect(null),
                ),
                ...phases.map((p) {
                  final n = hits.where((h) => h.sourcePhase == p).length;
                  return _PhaseChip(
                    label: '${_phaseLabel(p)} · $n',
                    active: selected == p,
                    onTap: () => onSelect(p),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),
          ],

          if (filtered.isEmpty)
            _EmptyField()
          else
            ...filtered.asMap().entries.map((e) => _SpecimenRow(
              index: e.key + 1,
              hit: e.value,
              isLast: e.key == filtered.length - 1,
            )),
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
}

class _PhaseChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PhaseChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.ink : AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: active ? AppColors.ink : AppColors.hairline),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: fontSans, fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? AppColors.canvas : AppColors.graphite,
          ),
        ),
      ),
    );
  }
}

class _SpecimenRow extends StatefulWidget {
  final int index;
  final EnhancedPatentHit hit;
  final bool isLast;
  const _SpecimenRow({required this.index, required this.hit, required this.isLast});

  @override
  State<_SpecimenRow> createState() => _SpecimenRowState();
}

class _SpecimenRowState extends State<_SpecimenRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hit;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(color: AppColors.rule),
          bottom: widget.isLast ? const BorderSide(color: AppColors.rule) : BorderSide.none,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Index column
                  SizedBox(
                    width: 40,
                    child: Text(
                      widget.index.toString().padLeft(2, '0'),
                      style: AppText.monoMeta.copyWith(color: AppColors.mist),
                    ),
                  ),
                  // Body
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(h.title,
                          style: AppText.display4.copyWith(fontSize: 18, height: 1.25),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(h.patentId, style: AppText.monoMeta),
                            if (h.assignee != null) ...[
                              Text('·', style: AppText.monoMeta),
                              Text(h.assignee!, style: AppText.monoMeta),
                            ],
                            if (h.date != null) ...[
                              Text('·', style: AppText.monoMeta),
                              Text(h.date!, style: AppText.monoMeta),
                            ],
                            Text('·', style: AppText.monoMeta),
                            Text(h.sourcePhasLabel.toUpperCase(), style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Match score — plain integer, right-aligned
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${h.scorePercent}',
                        style: AppText.display4.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text('MATCH', style: AppText.monoMeta),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_open) Padding(
            padding: const EdgeInsets.only(left: 40, right: 0, bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28, height: 1, color: AppColors.accentInk,
                ),
                const SizedBox(height: 12),
                Text('Why it\'s similar', style: AppText.labelSm.copyWith(color: AppColors.accentInk)),
                const SizedBox(height: 6),
                Text(h.whySimilar, style: AppText.body.copyWith(height: 1.6)),
                if (h.cpcCodes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: h.cpcCodes.take(6).map((c) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(c, style: TextStyle(
                        fontFamily: fontMono, fontSize: 10,
                        color: AppColors.graphite, letterSpacing: 0.5,
                      )),
                    )).toList(),
                  ),
                ],
                if (h.abstract_.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Abstract', style: AppText.labelSm.copyWith(color: AppColors.accentInk)),
                  const SizedBox(height: 6),
                  Text(h.abstract_, maxLines: 5, overflow: TextOverflow.ellipsis,
                    style: AppText.bodySm.copyWith(fontStyle: FontStyle.italic, height: 1.55)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A clean shelf.',
            style: AppText.display4.copyWith(fontStyle: FontStyle.italic, color: AppColors.accentInk)),
          const SizedBox(height: 8),
          Text(
            'No references matched the search. The field looks open — though absence of proof is not proof of absence.',
            style: AppText.body.copyWith(color: AppColors.graphite, height: 1.55),
          ),
        ],
      ),
    );
  }
}

// ── Analysis: novelty · obviousness · eligibility ───────────────────

class _AnalysisBlock extends StatelessWidget {
  final PatentAnalysisResponse a;
  const _AnalysisBlock({required this.a});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: 'IV · The reasoning', title: 'How we read it'),

          _AssessmentEntry(
            label: 'Novelty',
            question: 'Is it new?',
            riskLevel: a.noveltyAssessment.riskLevel,
            summary: a.noveltyAssessment.summary,
            details: [
              if (a.noveltyAssessment.closestReference != null)
                ('Closest reference', a.noveltyAssessment.closestReference!),
              if (a.noveltyAssessment.missingElements.isNotEmpty)
                ('Not found in prior art',
                  a.noveltyAssessment.missingElements.map((e) => '— $e').join('\n')),
            ],
          ),
          const SizedBox(height: 22),

          _AssessmentEntry(
            label: 'Non-obviousness',
            question: 'Is the leap real?',
            riskLevel: a.obviousnessAssessment.riskLevel,
            summary: a.obviousnessAssessment.summary,
            details: [
              if (a.obviousnessAssessment.combinationRefs.isNotEmpty)
                ('Could be combined', a.obviousnessAssessment.combinationRefs.join(', ')),
            ],
          ),

          if (a.eligibilityNote.applies) ...[
            const SizedBox(height: 22),
            _AssessmentEntry(
              label: 'Eligibility · §101',
              question: 'Is it the kind of thing the office grants?',
              riskLevel: 'medium',
              summary: a.eligibilityNote.summary,
              details: const [],
            ),
          ],
        ],
      ),
    );
  }
}

class _AssessmentEntry extends StatelessWidget {
  final String label;
  final String question;
  final String riskLevel;
  final String summary;
  final List<(String, String)> details;

  const _AssessmentEntry({
    required this.label,
    required this.question,
    required this.riskLevel,
    required this.summary,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    final c = _riskColor(riskLevel);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.md),
        color: AppColors.canvas,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Eyebrow(label)),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(_riskLabel(riskLevel).toUpperCase(), style: AppText.monoMeta.copyWith(color: c)),
            ],
          ),
          const SizedBox(height: 10),
          Text(question,
            style: AppText.display4.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 10),
          Text(summary, style: AppText.body.copyWith(height: 1.6)),
          for (final d in details) ...[
            const SizedBox(height: 14),
            Text(d.$1.toUpperCase(), style: AppText.monoMeta),
            const SizedBox(height: 4),
            Text(d.$2, style: AppText.bodySm.copyWith(height: 1.55)),
          ],
        ],
      ),
    );
  }
}

// ── Strategy ─────────────────────────────────────────────────────────

class _StrategyBlock extends StatelessWidget {
  final ClaimStrategy strategy;
  const _StrategyBlock({required this.strategy});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: 'V · Recommendation', title: 'The move'),

          StudioCard(
            background: AppColors.sunSoft,
            border: Border.all(color: Colors.transparent),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow('Recommended filing', color: AppColors.ink.withValues(alpha: 0.5)),
                const SizedBox(height: 10),
                Text(strategy.filingLabel,
                  style: AppText.display3.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 14),
                Text(strategy.rationale,
                  style: AppText.body.copyWith(height: 1.6)),
              ],
            ),
          ),

          if (strategy.riskAreas.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Watch for', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...strategy.riskAreas.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.warm),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(r, style: AppText.body.copyWith(height: 1.55))),
                ],
              ),
            )),
          ],

          if (strategy.suggestedIndependentClaims.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text('Draft claims', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...strategy.suggestedIndependentClaims.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.hairline),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text('${e.key + 1}.',
                        style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                    ),
                    Expanded(
                      child: Text(e.value,
                        style: AppText.body.copyWith(fontStyle: FontStyle.italic, height: 1.55)),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }
}

// ── Invention analysis (how the system read the idea) ───────────────

class _InventionBlock extends StatelessWidget {
  final InventionAnalysis inv;
  const _InventionBlock({required this.inv});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(eyebrow: 'Appendix · Method', title: 'How we read the idea'),

          Text('Core concept', style: AppText.monoMeta),
          const SizedBox(height: 6),
          Text(inv.coreConcept, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: 22),

          if (inv.essentialElements.isNotEmpty) ...[
            Text('Essential elements', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...inv.essentialElements.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 26,
                    child: Text('${e.key + 1}'.padLeft(2, '0'),
                      style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                  ),
                  Expanded(child: Text(e.value, style: AppText.body.copyWith(height: 1.55))),
                ],
              ),
            )),
            const SizedBox(height: 22),
          ],

          if (inv.cpcCodes.isNotEmpty) ...[
            Text('CPC classifications', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...inv.cpcCodes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.hairline),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(c.code,
                      style: TextStyle(fontFamily: fontMono, fontSize: 10,
                        color: AppColors.accentInk, letterSpacing: 0.5, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(c.description,
                    style: AppText.bodySm.copyWith(height: 1.5))),
                ],
              ),
            )),
            const SizedBox(height: 22),
          ],

          if (inv.searchStrategies.isNotEmpty) ...[
            Text('Queries', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...inv.searchStrategies.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('"${s.query}"',
                      style: AppText.body.copyWith(fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(width: 10),
                  Text(_approach(s.approach).toUpperCase(),
                    style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                ],
              ),
            )),
            const SizedBox(height: 22),
          ],

          if (inv.alternativeImplementations.isNotEmpty) ...[
            Text('Adjacent framings', style: AppText.monoMeta),
            const SizedBox(height: 10),
            ...inv.alternativeImplementations.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8, right: 10),
                    child: SizedBox(width: 14, child: Divider(color: AppColors.mist, thickness: 1)),
                  ),
                  Expanded(child: Text(a, style: AppText.body.copyWith(height: 1.55))),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  String _approach(String a) {
    switch (a) {
      case 'function_words': return 'Function';
      case 'technical_structure': return 'Structure';
      case 'use_case': return 'Use case';
      case 'synonyms': return 'Synonyms';
      default: return a;
    }
  }
}

// ── Disclaimer ──────────────────────────────────────────────────────

class _DisclaimerBlock extends StatelessWidget {
  final String text;
  const _DisclaimerBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(bottom: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.hairline),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 10),
              child: Icon(Icons.info_outline_rounded, size: 14, color: AppColors.mist),
            ),
            Expanded(
              child: Text(text,
                style: AppText.bodySm.copyWith(color: AppColors.graphite, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Foot actions ────────────────────────────────────────────────────

class _FootActions extends StatelessWidget {
  final bool canBuildThis;
  final bool isLoading;
  final VoidCallback onExport;
  final VoidCallback onBuildThis;

  const _FootActions({
    required this.canBuildThis,
    required this.isLoading,
    required this.onExport,
    required this.onBuildThis,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: _pageH.copyWith(top: 8),
      child: Column(
        children: [
          StudioButton(
            label: 'Export full analysis',
            icon: Icons.arrow_downward_rounded,
            kind: BtnKind.primary,
            onPressed: isLoading ? null : onExport,
          ),
          if (canBuildThis) ...[
            const SizedBox(height: 10),
            StudioButton(
              label: 'Draft the application',
              icon: Icons.edit_note_rounded,
              kind: BtnKind.accent,
              onPressed: isLoading ? null : onBuildThis,
            ),
          ],
        ],
      ),
    );
  }
}
