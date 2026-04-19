import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/idea_spec.dart';
import '../models/idea_variant.dart';
import '../models/product_input.dart';
import '../services/api_client.dart';
import '../services/credit_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../utils/pdf_downloader.dart';
import '../utils/pdf_generator.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/studio_widgets.dart';
import 'prior_art_screen.dart';

class IdeaDetailScreen extends StatefulWidget {
  final IdeaVariant variant;
  final String productText;
  final String? productURL;
  final String? sessionId;

  const IdeaDetailScreen({
    super.key,
    required this.variant,
    required this.productText,
    this.productURL,
    this.sessionId,
  });

  @override
  State<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends State<IdeaDetailScreen> {
  IdeaSpec? _spec;
  bool _isLoadingSpec = false;
  bool _isLoadingPatents = false;

  @override
  void initState() {
    super.initState();
    _loadSpec();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.variant;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Top bar
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    child: Row(
                      children: [
                        IconBtn(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text('THE DOSSIER', style: AppText.monoMeta),
                        const Spacer(),
                        IconBtn(
                          icon: Icons.content_copy_rounded,
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _buildMarkdown()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Copied to clipboard')),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        IconBtn(
                          icon: Icons.picture_as_pdf_outlined,
                          onPressed: _downloadPdf,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Hero
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          TierDot(tierOf(v.tier)),
                          const SizedBox(width: 10),
                          Text('File Nº ${_stubId(v.title)}', style: AppText.monoMeta),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(v.title, style: AppText.display2),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 28, height: 1, margin: const EdgeInsets.only(top: 12, right: 12), color: AppColors.ink),
                          Expanded(
                            child: Text(
                              v.summary,
                              style: AppText.bodyLg.copyWith(color: AppColors.graphite),
                            ),
                          ),
                        ],
                      ),
                      if (v.keywords.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: v.keywords
                              .map((k) => StudioChip(label: k))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Rich details
              if (v.isDetailed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                    child: _buildVariantDetails(v),
                  ),
                ),

              // Spec section
              if (_isLoadingSpec)
                SliverToBoxAdapter(child: _buildLoadingState())
              else if (_spec != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, 0),
                    child: _buildSpec(_spec!),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 140)),
            ],
          ),

          // Floating CTA
          if (_spec != null && !_isLoadingSpec)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
                  child: StudioButton(
                    label: 'Check prior art',
                    icon: Icons.gavel_rounded,
                    onPressed: _isLoadingPatents ? null : () => _searchPatents(_spec!),
                  ),
                ),
              ),
            ),

          if (_isLoadingPatents)
            const LoadingOverlay(
              message: 'Reading the patent ledger…\nThirty to sixty seconds.',
            ),
        ],
      ),
    );
  }

  // ── VARIANT DETAIL sections ─────────────────────────────────────
  Widget _buildVariantDetails(IdeaVariant v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v.scores != null) ...[
          SectionHeader(title: 'Scorecard', trailing: 'six axes · out of 10'),
          StudioCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: _ScoreTable(scores: v.scores!),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.targetCustomer != null && v.targetCustomer!.isNotEmpty) ...[
          SectionHeader(title: 'Who buys it'),
          Text(v.targetCustomer!, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.coreProblem != null && v.coreProblem!.isNotEmpty) ...[
          SectionHeader(title: 'The pinch'),
          Text(v.coreProblem!, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.solution != null && v.solution!.isNotEmpty) ...[
          SectionHeader(title: 'The solution'),
          Text(v.solution!, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.whyItWins.isNotEmpty) ...[
          SectionHeader(title: 'Why it wins'),
          ..._bulletList(v.whyItWins, bullet: Icons.check_rounded, bulletColor: AppColors.accent),
          const SizedBox(height: AppSpacing.lg),
        ],

        if ((v.monetization != null && v.monetization!.isNotEmpty) ||
            (v.unitEconomics != null && v.unitEconomics!.isNotEmpty)) ...[
          SectionHeader(title: 'Money'),
          StudioCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            background: AppColors.accentSoft,
            border: Border.all(color: Colors.transparent),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (v.monetization != null && v.monetization!.isNotEmpty)
                  Text(
                    v.monetization!,
                    style: AppText.display4.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.accentInk,
                    ),
                  ),
                if (v.unitEconomics != null && v.unitEconomics!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(v.unitEconomics!, style: AppText.bodySm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.defensibilityNote != null && v.defensibilityNote!.isNotEmpty) ...[
          SectionHeader(title: 'The moat'),
          Text(v.defensibilityNote!, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.mvp90Days != null && v.mvp90Days!.isNotEmpty) ...[
          SectionHeader(title: 'First ninety days'),
          Text(v.mvp90Days!, style: AppText.body.copyWith(height: 1.6)),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.goToMarket.isNotEmpty) ...[
          SectionHeader(title: 'Go-to-market'),
          ..._bulletList(v.goToMarket, bullet: Icons.arrow_forward_rounded),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (v.risks.isNotEmpty) ...[
          SectionHeader(title: 'Risks'),
          ..._bulletList(v.risks, bullet: Icons.priority_high_rounded, bulletColor: AppColors.warm),
          const SizedBox(height: AppSpacing.lg),
        ],
      ],
    );
  }

  List<Widget> _bulletList(List<String> items, {IconData bullet = Icons.circle, Color? bulletColor}) {
    return items.map((s) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3, right: 10),
            child: Icon(bullet, size: 14, color: bulletColor ?? AppColors.ink),
          ),
          Expanded(child: Text(s, style: AppText.body.copyWith(height: 1.55))),
        ],
      ),
    )).toList();
  }

  // ── SPEC sections ──────────────────────────────────────────────
  Widget _buildSpec(IdeaSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'Concept spec', trailing: 'what · how · against what'),
        _specBlock('A.', 'What makes it new', spec.novelty),
        const SizedBox(height: AppSpacing.lg),
        _specBlock('B.', 'How it works', spec.mechanism),
        const SizedBox(height: AppSpacing.lg),
        _specBlock('C.', 'What exists today', spec.baseline),
        const SizedBox(height: AppSpacing.lg),

        SectionHeader(title: 'Differentiators'),
        ..._bulletList(spec.differentiators, bullet: Icons.check_rounded, bulletColor: AppColors.accent),

        if (spec.keywords.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'Patent-search keywords'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: spec.keywords.map((k) => StudioChip(label: k)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _specBlock(String marker, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            marker,
            style: TextStyle(fontFamily: fontMono, fontSize: 11, color: AppColors.mist),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.display4),
              const SizedBox(height: 4),
              Text(body, style: AppText.body.copyWith(height: 1.6, color: AppColors.graphite)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Breaking down what makes this clever…', style: AppText.bodySm),
        ],
      ),
    );
  }

  // ── Utilities ──────────────────────────────────────────────────
  String _stubId(String title) {
    final hash = title.hashCode.abs() % 10000;
    return hash.toString().padLeft(4, '0');
  }

  String _buildMarkdown() {
    final v = widget.variant;
    final buf = StringBuffer();
    buf.writeln('# ${v.title}\n');
    buf.writeln('**Product:** ${widget.productText}\n');
    buf.writeln('## Summary\n${v.summary}\n');
    if (v.keywords.isNotEmpty) buf.writeln('**Keywords:** ${v.keywords.join(", ")}\n');
    if (v.isDetailed) {
      if (v.scores != null) {
        buf.writeln('## Scorecard');
        final s = v.scores!;
        buf.writeln('- Urgency: ${s.urgency}/10');
        buf.writeln('- Differentiation: ${s.differentiation}/10');
        buf.writeln('- Speed to Revenue: ${s.speedToRevenue}/10');
        buf.writeln('- Margin: ${s.margin}/10');
        buf.writeln('- Defensibility: ${s.defensibility}/10');
        buf.writeln('- Distribution: ${s.distribution}/10\n');
      }
      if (v.targetCustomer?.isNotEmpty ?? false) buf.writeln('## Target customer\n${v.targetCustomer}\n');
      if (v.coreProblem?.isNotEmpty ?? false) buf.writeln('## Core problem\n${v.coreProblem}\n');
      if (v.solution?.isNotEmpty ?? false) buf.writeln('## Solution\n${v.solution}\n');
      if (v.whyItWins.isNotEmpty) { buf.writeln('## Why it wins'); for (final w in v.whyItWins) buf.writeln('- $w'); buf.writeln(); }
      if (v.monetization?.isNotEmpty ?? false) buf.writeln('## Monetization\n${v.monetization}\n');
      if (v.unitEconomics?.isNotEmpty ?? false) buf.writeln('### Unit economics\n${v.unitEconomics}\n');
      if (v.defensibilityNote?.isNotEmpty ?? false) buf.writeln('## Defensibility\n${v.defensibilityNote}\n');
      if (v.mvp90Days?.isNotEmpty ?? false) buf.writeln('## MVP in 90 days\n${v.mvp90Days}\n');
      if (v.goToMarket.isNotEmpty) { buf.writeln('## Go-to-market'); for (final g in v.goToMarket) buf.writeln('- $g'); buf.writeln(); }
      if (v.risks.isNotEmpty) { buf.writeln('## Risks'); for (final r in v.risks) buf.writeln('- $r'); buf.writeln(); }
    }
    if (_spec != null) {
      buf.writeln('---\n\n## Concept spec\n');
      buf.writeln('### Novelty\n${_spec!.novelty}\n');
      buf.writeln('### Mechanism\n${_spec!.mechanism}\n');
      buf.writeln('### Baseline\n${_spec!.baseline}\n');
      buf.writeln('### Differentiators'); for (final d in _spec!.differentiators) buf.writeln('- $d'); buf.writeln();
      buf.writeln('### Keywords\n${_spec!.keywords.join(", ")}\n');
    }
    buf.writeln('---\n*Generated by MouseTrap Studio*');
    return buf.toString();
  }

  Future<void> _downloadPdf() async {
    try {
      final bytes = await PdfGenerator.generateFromMarkdown(
        title: widget.variant.title,
        content: _buildMarkdown(),
      );
      final safeName = widget.variant.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      downloadPdfBytes(bytes, '$safeName.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF failed: $e')),
        );
      }
    }
  }

  Future<void> _loadSpec() async {
    setState(() => _isLoadingSpec = true);
    try {
      final spec = await ApiClient.instance.generateSpec(
        productText: widget.productText,
        variant: widget.variant,
      );
      if (mounted) {
        setState(() => _spec = spec);
        if (widget.sessionId != null) {
          ApiClient.instance.updateSession(widget.sessionId!, {
            'spec_json': spec.toJson(),
            'status': 'spec_generated',
          }).catchError((_) {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSpec = false);
    }
  }

  void _showBuyCreditsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuyCreditsSheet(),
    );
  }

  Future<void> _searchPatents(IdeaSpec spec) async {
    if (!CreditService.instance.hasCredits) {
      _showBuyCreditsSheet();
      return;
    }
    setState(() => _isLoadingPatents = true);
    try {
      final analysisResponse = await ApiClient.instance.analyzePatents(
        productText: widget.productText,
        variant: widget.variant,
        spec: spec,
      );
      CreditService.instance.localDeduct();

      if (widget.sessionId != null) {
        ApiClient.instance.updateSession(widget.sessionId!, {
          'patent_hits_json': analysisResponse.hits.map((h) => h.toJson()).toList(),
          'patent_confidence': analysisResponse.confidence,
          'status': 'patents_searched',
        }).catchError((_) {});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PriorArtScreen(
            product: ProductInput(text: widget.productText, url: widget.productURL),
            variant: widget.variant,
            spec: spec,
            analysisResponse: analysisResponse,
            sessionId: widget.sessionId,
          ),
        ),
      );
    } on InsufficientCreditsException {
      if (mounted) _showBuyCreditsSheet();
    } on UnauthorizedException {
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Patent search failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingPatents = false);
    }
  }
}

class _ScoreTable extends StatelessWidget {
  final IdeaScores scores;
  const _ScoreTable({required this.scores});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Urgency', scores.urgency),
      ('Differentiation', scores.differentiation),
      ('Speed to revenue', scores.speedToRevenue),
      ('Margin', scores.margin),
      ('Defensibility', scores.defensibility),
      ('Distribution', scores.distribution),
    ];
    return Column(
      children: items
          .asMap()
          .entries
          .map((e) {
            final isLast = e.key == items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(e.value.$1, style: AppText.caption.copyWith(color: AppColors.graphite)),
                  ),
                  Expanded(child: ScoreBar(value: e.value.$2 / 10.0)),
                  const SizedBox(width: 8),
                  Text('${e.value.$2}', style: AppText.monoMeta),
                ],
              ),
            );
          })
          .toList(),
    );
  }
}
