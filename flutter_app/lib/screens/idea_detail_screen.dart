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
import '../widgets/whiskers_widgets.dart';
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
                    padding: const EdgeInsets.fromLTRB(
                        20, 8, 20, 0),
                    child: Row(
                      children: [
                        IconBtn(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        IconBtn(
                          icon: Icons.content_copy_rounded,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(
                                    text: _buildMarkdown()));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content: Text(
                                        'Copied to clipboard')));
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

              // Hero card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: WCard(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC4B5FD), AppColors.lav],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Pill(_tierLabel(v.tier),
                                bg: Colors.white24,
                                fg: Colors.white),
                            const Spacer(),
                            const Mascot(
                                pose: MascotPose.inventor,
                                size: 44),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(v.title,
                            style: AppText.display2
                                .copyWith(
                                    color: Colors.white,
                                    fontSize: 22)),
                        const SizedBox(height: 8),
                        Text(v.summary,
                            style: AppText.body.copyWith(
                                color: Colors.white70,
                                height: 1.5)),
                        if (v.scores != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(
                                  alpha: 0.15),
                              borderRadius: BorderRadius.circular(
                                  AppRadius.md),
                            ),
                            child: _ScoreStrip(
                                scores: v.scores!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // Keywords
              if (v.keywords.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 14, 20, 0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: v.keywords
                          .map((k) => Pill(k))
                          .toList(),
                    ),
                  ),
                ),

              // Variant details
              if (v.isDetailed)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 0),
                    child: _buildVariantDetails(v),
                  ),
                ),

              // Spec section
              if (_isLoadingSpec)
                SliverToBoxAdapter(
                    child: _buildLoadingState())
              else if (_spec != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        20, 20, 20, 0),
                    child: _buildSpec(_spec!),
                  ),
                ),

              const SliverToBoxAdapter(
                  child: SizedBox(height: 140)),
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
                  padding: const EdgeInsets.fromLTRB(
                      20, 8, 20, 16),
                  child: PrimaryBtn(
                    label: 'Check Prior Art',
                    trailing: Icons.gavel_rounded,
                    onPressed: _isLoadingPatents
                        ? null
                        : () => _searchPatents(_spec!),
                  ),
                ),
              ),
            ),

          if (_isLoadingPatents)
            const LoadingOverlay(
              message:
                  'Reading the patent ledger…\nThirty to sixty seconds.',
            ),
        ],
      ),
    );
  }

  String _tierLabel(String tier) {
    switch (tier) {
      case 'top': return 'TOP PICK';
      case 'moonshot': return 'MOONSHOT';
      case 'upgrade': return 'UPGRADE';
      case 'adjacent': return 'ADJACENT';
      case 'recurring': return 'RECURRING';
      default: return tier.toUpperCase();
    }
  }

  Widget _buildVariantDetails(IdeaVariant v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (v.scores != null) ...[
          const SectionHeader('Scorecard'),
          WCard(
            child: _ScoreTable(scores: v.scores!),
          ),
          const SizedBox(height: 16),
        ],
        if (v.targetCustomer != null &&
            v.targetCustomer!.isNotEmpty) ...[
          const SectionHeader('Who Buys It'),
          WCard(
            child: Text(v.targetCustomer!,
                style: AppText.body.copyWith(height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (v.coreProblem != null &&
            v.coreProblem!.isNotEmpty) ...[
          const SectionHeader('The Pinch'),
          WCard(
            child: Text(v.coreProblem!,
                style: AppText.body.copyWith(height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (v.solution != null && v.solution!.isNotEmpty) ...[
          const SectionHeader('The Solution'),
          WCard(
            child: Text(v.solution!,
                style: AppText.body.copyWith(height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (v.whyItWins.isNotEmpty) ...[
          const SectionHeader('Why It Wins'),
          WCard(
            child: Column(
              children: v.whyItWins
                  .map((r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                  top: 4, right: 8),
                              child: Icon(
                                  Icons.check_circle_rounded,
                                  size: 14,
                                  color: AppColors.success),
                            ),
                            Expanded(
                              child: Text(r,
                                  style: AppText.body
                                      .copyWith(height: 1.5)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if ((v.monetization != null &&
                v.monetization!.isNotEmpty) ||
            (v.unitEconomics != null &&
                v.unitEconomics!.isNotEmpty)) ...[
          const SectionHeader('Money'),
          WCard(
            color: AppColors.mintBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (v.monetization != null &&
                    v.monetization!.isNotEmpty)
                  Text(v.monetization!,
                      style: AppText.bodyBold
                          .copyWith(color: AppColors.success)),
                if (v.unitEconomics != null &&
                    v.unitEconomics!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(v.unitEconomics!,
                      style: AppText.body),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (v.defensibilityNote != null &&
            v.defensibilityNote!.isNotEmpty) ...[
          const SectionHeader('The Moat'),
          WCard(
            child: Text(v.defensibilityNote!,
                style: AppText.body.copyWith(height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (v.mvp90Days != null &&
            v.mvp90Days!.isNotEmpty) ...[
          const SectionHeader('First 90 Days'),
          WCard(
            child: Text(v.mvp90Days!,
                style: AppText.body.copyWith(height: 1.6)),
          ),
          const SizedBox(height: 16),
        ],
        if (v.goToMarket.isNotEmpty) ...[
          const SectionHeader('Go-to-Market'),
          WCard(
            child: Column(
              children: v.goToMarket
                  .map((g) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                  top: 4, right: 8),
                              child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: AppColors.lav),
                            ),
                            Expanded(
                              child: Text(g,
                                  style: AppText.body
                                      .copyWith(height: 1.5)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (v.risks.isNotEmpty) ...[
          const SectionHeader('Risks'),
          WCard(
            color: AppColors.peachBg,
            child: Column(
              children: v.risks
                  .map((r) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(
                                  top: 4, right: 8),
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
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSpec(IdeaSpec spec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Concept Spec'),
        WCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _specBlock('A', 'What makes it new', spec.novelty),
              const SizedBox(height: 14),
              _specBlock('B', 'How it works', spec.mechanism),
              const SizedBox(height: 14),
              _specBlock('C', 'What exists today', spec.baseline),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionHeader('Differentiators'),
        WCard(
          child: Column(
            children: spec.differentiators
                .map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                top: 4, right: 8),
                            child: Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: AppColors.success),
                          ),
                          Expanded(
                            child: Text(d,
                                style: AppText.body
                                    .copyWith(height: 1.5)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
        if (spec.keywords.isNotEmpty) ...[
          const SizedBox(height: 16),
          const SectionHeader('Patent-Search Keywords'),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: spec.keywords
                .map((k) => Pill(k))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _specBlock(String marker, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.lavLight,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Center(
            child: Text(marker,
                style: AppText.tiny.copyWith(
                    color: AppColors.lavDark,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.bodyBold),
              const SizedBox(height: 4),
              Text(body,
                  style: AppText.body.copyWith(
                      height: 1.6,
                      color: AppColors.inkSoft)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.lav),
          ),
          SizedBox(height: 12),
          Text('Breaking down what makes this clever…'),
        ],
      ),
    );
  }

  String _buildMarkdown() {
    final v = widget.variant;
    final buf = StringBuffer();
    buf.writeln('# ${v.title}\n');
    buf.writeln('**Product:** ${widget.productText}\n');
    buf.writeln('## Summary\n${v.summary}\n');
    if (v.keywords.isNotEmpty) {
      buf.writeln('**Keywords:** ${v.keywords.join(", ")}\n');
    }
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
      if (v.targetCustomer?.isNotEmpty ?? false) {
        buf.writeln('## Target customer\n${v.targetCustomer}\n');
      }
      if (v.coreProblem?.isNotEmpty ?? false) {
        buf.writeln('## Core problem\n${v.coreProblem}\n');
      }
      if (v.solution?.isNotEmpty ?? false) {
        buf.writeln('## Solution\n${v.solution}\n');
      }
      if (v.whyItWins.isNotEmpty) {
        buf.writeln('## Why it wins');
        for (final w in v.whyItWins) buf.writeln('- $w');
        buf.writeln();
      }
      if (v.monetization?.isNotEmpty ?? false) {
        buf.writeln('## Monetization\n${v.monetization}\n');
      }
      if (v.unitEconomics?.isNotEmpty ?? false) {
        buf.writeln('### Unit economics\n${v.unitEconomics}\n');
      }
      if (v.defensibilityNote?.isNotEmpty ?? false) {
        buf.writeln('## Defensibility\n${v.defensibilityNote}\n');
      }
      if (v.mvp90Days?.isNotEmpty ?? false) {
        buf.writeln('## MVP in 90 days\n${v.mvp90Days}\n');
      }
      if (v.goToMarket.isNotEmpty) {
        buf.writeln('## Go-to-market');
        for (final g in v.goToMarket) buf.writeln('- $g');
        buf.writeln();
      }
      if (v.risks.isNotEmpty) {
        buf.writeln('## Risks');
        for (final r in v.risks) buf.writeln('- $r');
        buf.writeln();
      }
    }
    if (_spec != null) {
      buf.writeln('---\n\n## Concept spec\n');
      buf.writeln('### Novelty\n${_spec!.novelty}\n');
      buf.writeln('### Mechanism\n${_spec!.mechanism}\n');
      buf.writeln('### Baseline\n${_spec!.baseline}\n');
      buf.writeln('### Differentiators');
      for (final d in _spec!.differentiators) buf.writeln('- $d');
      buf.writeln();
      buf.writeln('### Keywords\n${_spec!.keywords.join(", ")}\n');
    }
    buf.writeln('---\n*Generated by MouseTrap*');
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
            const SnackBar(content: Text('PDF downloaded')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF failed: $e')));
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
            SnackBar(content: Text(e.toString())));
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
          'patent_hits_json':
              analysisResponse.hits.map((h) => h.toJson()).toList(),
          'patent_confidence': analysisResponse.confidence,
          'status': 'patents_searched',
        }).catchError((_) {});
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PriorArtScreen(
            product: ProductInput(
                text: widget.productText,
                url: widget.productURL),
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
            SnackBar(content: Text('Patent search failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingPatents = false);
    }
  }
}

// ── Score strip (used in hero card) ─────────────────────────────────
class _ScoreStrip extends StatelessWidget {
  final IdeaScores scores;
  const _ScoreStrip({required this.scores});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('URG', scores.urgency),
      ('DIFF', scores.differentiation),
      ('SPD', scores.speedToRevenue),
    ];
    return Row(
      children: items.map((item) {
        final (label, score) = item;
        return Expanded(
          child: Column(
            children: [
              Text('$score',
                  style: AppText.display2
                      .copyWith(color: Colors.white, fontSize: 22)),
              Text(label,
                  style: AppText.tiny
                      .copyWith(color: Colors.white70)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Score table (used in variant details) ────────────────────────────
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
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(e.value.$1,
                        style: AppText.caption),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      child: LinearProgressIndicator(
                        value: e.value.$2 / 10.0,
                        minHeight: 6,
                        backgroundColor: AppColors.hairline,
                        valueColor:
                            const AlwaysStoppedAnimation(
                                AppColors.lav),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value.$2}',
                      style: AppText.bodyBold
                          .copyWith(color: AppColors.lav)),
                ],
              ),
            );
          })
          .toList(),
    );
  }
}
