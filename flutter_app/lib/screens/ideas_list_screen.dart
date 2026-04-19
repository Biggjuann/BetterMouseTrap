import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../models/idea_variant.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/studio_widgets.dart';
import 'idea_detail_screen.dart';

class IdeasListScreen extends StatefulWidget {
  final List<IdeaVariant> variants;
  final CustomerTruth? customerTruth;
  final String productText;
  final String? productURL;
  final String? sessionId;
  final bool random;

  const IdeasListScreen({
    super.key,
    required this.variants,
    required this.productText,
    this.customerTruth,
    this.productURL,
    this.sessionId,
    this.random = false,
  });

  @override
  State<IdeasListScreen> createState() => _IdeasListScreenState();
}

class _IdeasListScreenState extends State<IdeasListScreen> {
  late List<IdeaVariant> _variants;
  CustomerTruth? _customerTruth;
  bool _isLoading = false;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _variants = widget.variants;
    _customerTruth = widget.customerTruth;
    _sessionId = widget.sessionId;
  }

  List<IdeaVariant> _byTier(String tier) =>
      _variants.where((v) => v.tier == tier).toList();

  Future<void> _regenerate() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.instance.generateIdeas(
        text: widget.random ? '' : widget.productText,
        random: widget.random,
      );

      if (_sessionId != null) {
        ApiClient.instance.updateSession(_sessionId!, {
          'variants_json': response.variants.map((v) => v.toJson()).toList(),
          'status': 'ideas_generated',
        }).catchError((_) {});
      }

      if (mounted) {
        setState(() {
          _variants = response.variants;
          _customerTruth = response.customerTruth;
        });
      }
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

  void _openDetail(IdeaVariant variant, int index) {
    if (_sessionId != null) {
      ApiClient.instance.updateSession(_sessionId!, {
        'selected_variant_json': variant.toJson(),
        'title': variant.title,
      }).catchError((_) {});
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IdeaDetailScreen(
          variant: variant,
          productText: widget.productText,
          productURL: widget.productURL,
          sessionId: _sessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPicks = _byTier('top');
    final moonshots = _byTier('moonshot');
    final upgrades = _byTier('upgrade');
    final adjacent = _byTier('adjacent');
    final recurring = _byTier('recurring');

    final all = <({String section, IdeaVariant v})>[
      for (final v in topPicks) (section: 'top', v: v),
      for (final v in moonshots) (section: 'moonshot', v: v),
      for (final v in upgrades) (section: 'upgrade', v: v),
      for (final v in adjacent) (section: 'adjacent', v: v),
      for (final v in recurring) (section: 'recurring', v: v),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBtn(
                              icon: Icons.arrow_back_rounded,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text('THE BRIEF', style: AppText.monoMeta),
                            const Spacer(),
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Eyebrow('Study of · ${widget.productText.isEmpty ? "an unknown specimen" : widget.productText}'),
                        const SizedBox(height: AppSpacing.md),
                        RichText(
                          text: TextSpan(
                            style: AppText.display1,
                            children: [
                              const TextSpan(text: 'Seven\n'),
                              TextSpan(
                                text: 'angles.',
                                style: AppText.display1.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          'Tiered by ambition. Scored on six axes. Tap any for the full dossier, prior-art read, and one-pager.',
                          style: AppText.bodyLg.copyWith(color: AppColors.graphite),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),

              if (_customerTruth != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                    child: _CustomerTruthCard(truth: _customerTruth!),
                  ),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, 120),
                sliver: SliverList.separated(
                  itemCount: all.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final entry = all[i];
                    final prev = i > 0 ? all[i - 1].section : null;
                    final showHeader = entry.section != prev;
                    final compact = entry.section == 'upgrade' ||
                        entry.section == 'adjacent' ||
                        entry.section == 'recurring';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHeader) ...[
                          if (i > 0) const SizedBox(height: AppSpacing.lg),
                          _SectionHeading(tier: entry.section, count: _byTier(entry.section).length),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        _IdeaCard(
                          index: i + 1,
                          variant: entry.v,
                          compact: compact,
                          onTap: () => _openDetail(entry.v, i),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.base),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.hairline),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.ink.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _regenerate,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text(
                            'New set',
                            style: TextStyle(
                              fontFamily: fontSans,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 22, color: AppColors.hairline),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _regenerate,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.ink,
                            foregroundColor: AppColors.canvas,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            textStyle: const TextStyle(
                              fontFamily: fontSans,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                          label: const Text('Regenerate'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const LoadingOverlay(
              message: 'Restudying the specimen…',
            ),
        ],
      ),
    );
  }
}

// ── Customer Truth — paper callout ──────────────────────────────────

class _CustomerTruthCard extends StatelessWidget {
  final CustomerTruth truth;
  const _CustomerTruthCard({required this.truth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow('Customer truth · field notes', color: AppColors.accentInk),
          const SizedBox(height: AppSpacing.md),
          if (truth.buyer.isNotEmpty)
            _truthRow('Buyer', truth.buyer),
          if (truth.jobToBeDone.isNotEmpty)
            _truthRow('Job to be done', truth.jobToBeDone),
          if (truth.purchaseDrivers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Why they buy', style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: truth.purchaseDrivers
                  .map((d) => StudioChip(label: d))
                  .toList(),
            ),
          ],
          if (truth.complaints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Where it pinches', style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: truth.complaints
                  .map((c) => StudioChip(label: c, tone: ChipTone.warm))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _truthRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: AppText.body.copyWith(color: AppColors.ink, height: 1.5),
          children: [
            TextSpan(
              text: '$label — ',
              style: const TextStyle(
                fontFamily: fontMono,
                fontSize: 11,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ── Section heading ─────────────────────────────────────────────────
class _SectionHeading extends StatelessWidget {
  final String tier;
  final int count;
  const _SectionHeading({required this.tier, required this.count});

  @override
  Widget build(BuildContext context) {
    final label = switch (tier) {
      'top' => 'Top picks',
      'moonshot' => 'Moonshots',
      'upgrade' => 'Upgrades',
      'adjacent' => 'Adjacent products',
      'recurring' => 'Recurring revenue',
      _ => tier,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: AppText.display4),
        const SizedBox(width: 10),
        Text('· $count', style: AppText.monoMeta),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: AppColors.hairline, margin: const EdgeInsets.only(bottom: 8)),
        ),
      ],
    );
  }
}

// ── Idea card ───────────────────────────────────────────────────────
class _IdeaCard extends StatelessWidget {
  final int index;
  final IdeaVariant variant;
  final bool compact;
  final VoidCallback onTap;

  const _IdeaCard({
    required this.index,
    required this.variant,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final num = index.toString().padLeft(2, '0');

    return StudioCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      num,
                      style: TextStyle(
                        fontFamily: fontMono,
                        fontSize: 11,
                        color: AppColors.mist,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TierDot(tierOf(variant.tier)),
                        const SizedBox(height: 8),
                        Text(variant.title, style: AppText.display3),
                        const SizedBox(height: 4),
                        Text(
                          variant.summary,
                          style: AppText.body.copyWith(color: AppColors.graphite),
                          maxLines: compact ? 2 : null,
                          overflow: compact ? TextOverflow.ellipsis : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ink),
                ],
              ),

              if (!compact) ...[
                if (variant.targetCustomer != null && variant.targetCustomer!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _metaLine(Icons.person_outline_rounded, variant.targetCustomer!),
                ],
                if (variant.monetization != null && variant.monetization!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _metaLine(Icons.payments_outlined, variant.monetization!, emphasize: true),
                ],
                if (variant.scores != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: _ScoreGrid(scores: variant.scores!),
                  ),
                ],
                if (variant.whyItWins.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ...variant.whyItWins.take(3).map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 7, right: 8),
                              child: Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Expanded(child: Text(r, style: AppText.bodySm)),
                          ],
                        ),
                      )),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaLine(IconData icon, String text, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 32),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.mist),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: fontSans,
                fontSize: 12.5,
                color: emphasize ? AppColors.ink : AppColors.graphite,
                fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreGrid extends StatelessWidget {
  final IdeaScores scores;
  const _ScoreGrid({required this.scores});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('URG', scores.urgency),
      ('DIFF', scores.differentiation),
      ('SPD', scores.speedToRevenue),
      ('MAR', scores.margin),
      ('DEF', scores.defensibility),
      ('DIST', scores.distribution),
    ];

    return Row(
      children: items.map((item) {
        final (label, score) = item;
        return Expanded(
          child: Column(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 9,
                  color: AppColors.mist,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
