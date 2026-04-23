import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../models/idea_variant.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/whiskers_widgets.dart';
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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

  // Emoji + bg color per tier position
  static const _tileStyles = [
    ('🔥', AppColors.sunBg),
    ('🚀', AppColors.lavLight),
    ('⚡', AppColors.mintBg),
    ('🎯', AppColors.peachBg),
    ('💡', AppColors.pinkBg),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('🔥 Top Picks', _byTier('top')),
      ('🚀 Moonshots', _byTier('moonshot')),
      ('⚡ Quick Wins', _byTier('upgrade')),
      ('🎯 Adjacent', _byTier('adjacent')),
      ('🔁 Recurring', _byTier('recurring')),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBtn(
                              icon: Icons.arrow_back_rounded,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 4),
                            IconBtn(
                              icon: Icons.home_rounded,
                              onPressed: () => Navigator.of(context)
                                  .popUntil((r) => r.isFirst),
                            ),
                            const Spacer(),
                            const Mascot(
                                pose: MascotPose.cheese, size: 36),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('7 Ideas for', style: AppText.caption),
                        Text(
                          widget.productText.isEmpty
                              ? 'a surprise product'
                              : widget.productText,
                          style: AppText.display1,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tiered by ambition · scored on six axes · tap any for the full dossier.',
                          style: AppText.caption,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),

              if (_customerTruth != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: _CustomerTruthCard(truth: _customerTruth!),
                  ),
                ),

              SliverPadding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final section = sections[i];
                      final (label, variants) = section;
                      if (variants.isEmpty) return const SizedBox.shrink();
                      return _TierSection(
                        label: label,
                        variants: variants,
                        tileStyles: _tileStyles,
                        onTap: (v) => _openDetail(
                            v, _variants.indexOf(v)),
                      );
                    },
                    childCount: sections.length,
                  ),
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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                    boxShadow: AppShadows.card,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: _isLoading ? null : _regenerate,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.ink,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.refresh_rounded,
                              size: 18),
                          label: Text('New set',
                              style: AppText.bodyBold),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 22,
                          color: AppColors.hairline),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFA78BFA),
                                AppColors.lav
                              ],
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                  AppRadius.pill),
                              onTap: _isLoading ? null : _regenerate,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                        Icons.auto_awesome_rounded,
                                        color: Colors.white,
                                        size: 16),
                                    const SizedBox(width: 6),
                                    Text('Regenerate',
                                        style:
                                            AppText.btnPrimary.copyWith(
                                                fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                message: 'Restudying the specimen…'),
        ],
      ),
    );
  }
}

// ── Customer truth card ──────────────────────────────────────────────
class _CustomerTruthCard extends StatelessWidget {
  final CustomerTruth truth;
  const _CustomerTruthCard({required this.truth});

  @override
  Widget build(BuildContext context) {
    return WCard(
      color: AppColors.lavLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline_rounded,
                  size: 16, color: AppColors.lavDark),
              const SizedBox(width: 6),
              Text('Customer Truth',
                  style: AppText.sectionTitle
                      .copyWith(color: AppColors.lavDark)),
            ],
          ),
          const SizedBox(height: 10),
          if (truth.buyer.isNotEmpty)
            _row('Buyer', truth.buyer),
          if (truth.jobToBeDone.isNotEmpty)
            _row('Job to be done', truth.jobToBeDone),
          if (truth.purchaseDrivers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Why they buy',
                style: AppText.tiny
                    .copyWith(color: AppColors.lavDark)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: truth.purchaseDrivers
                  .map((d) => Pill(d,
                      bg: AppColors.lav, fg: Colors.white))
                  .toList(),
            ),
          ],
          if (truth.complaints.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Pain points',
                style: AppText.tiny
                    .copyWith(color: AppColors.lavDark)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: truth.complaints
                  .map((c) => Pill(c,
                      bg: AppColors.peachBg,
                      fg: AppColors.danger))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: AppText.body.copyWith(color: AppColors.ink),
          children: [
            TextSpan(
                text: '$label — ',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

// ── Tier section ─────────────────────────────────────────────────────
class _TierSection extends StatelessWidget {
  final String label;
  final List<IdeaVariant> variants;
  final List<(String, Color)> tileStyles;
  final void Function(IdeaVariant) onTap;

  const _TierSection({
    required this.label,
    required this.variants,
    required this.tileStyles,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(label),
        ...variants.asMap().entries.map((e) {
          final (emoji, bg) =
              tileStyles[e.key % tileStyles.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IdeaCard(
              variant: e.value,
              emoji: emoji,
              tileBg: bg,
              onTap: () => onTap(e.value),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Idea card ────────────────────────────────────────────────────────
class _IdeaCard extends StatelessWidget {
  final IdeaVariant variant;
  final String emoji;
  final Color tileBg;
  final VoidCallback onTap;

  const _IdeaCard({
    required this.variant,
    required this.emoji,
    required this.tileBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return WCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(variant.title,
                    style: AppText.display3
                        .copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                  variant.summary,
                  style: AppText.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant.scores != null) ...[
                  const SizedBox(height: 8),
                  _ScoreRow(scores: variant.scores!),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final IdeaScores scores;
  const _ScoreRow({required this.scores});

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
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Column(
            children: [
              Text('$score',
                  style: AppText.display3
                      .copyWith(fontSize: 18, color: AppColors.lav)),
              Text(label,
                  style: AppText.tiny
                      .copyWith(letterSpacing: 0.5)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
