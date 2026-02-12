import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../models/idea_variant.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/loading_overlay.dart';
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
          'variants_json':
              response.variants.map((v) => v.toJson()).toList(),
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

  void _openDetail(IdeaVariant variant) {
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

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.base, AppSpacing.lg, 0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new,
                                  size: 20),
                              color: AppColors.primary,
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            Text(
                              'SELLABLE IDEAS',
                              style: TextStyle(
                                color:
                                    AppColors.primary.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.base),
                        Text(
                          'Invention Ideas',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),

              // Customer Truth card
              if (_customerTruth != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: _CustomerTruthCard(truth: _customerTruth!),
                  ),
                ),

              // Top Picks section
              if (topPicks.isNotEmpty) ...[
                _sectionHeader('Top Picks', Icons.star, AppColors.primary),
                _detailedCardList(topPicks),
              ],

              // Moonshot section
              if (moonshots.isNotEmpty) ...[
                _sectionHeader(
                    'Moonshot', Icons.rocket_launch, AppColors.purpleText),
                _detailedCardList(moonshots),
              ],

              // More Upgrades section
              if (upgrades.isNotEmpty) ...[
                _sectionHeader(
                    'More Upgrades', Icons.trending_up, AppColors.blueText),
                _compactCardList(upgrades),
              ],

              // Adjacent Products section
              if (adjacent.isNotEmpty) ...[
                _sectionHeader(
                    'Adjacent Products', Icons.grid_view, AppColors.teal),
                _compactCardList(adjacent),
              ],

              // Recurring Revenue section
              if (recurring.isNotEmpty) ...[
                _sectionHeader('Recurring Revenue', Icons.autorenew,
                    AppColors.emeraldText),
                _compactCardList(recurring),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // FAB — "Generate New Ideas"
          Positioned(
            bottom: AppSpacing.xl,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: AppShadows.button,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: FilledButton(
                  onPressed: _isLoading ? null : _regenerate,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.base,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_fix_high, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Generate New Ideas'),
                    ],
                  ),
                ),
              ),
            ),
          ),

          if (_isLoading)
            const LoadingOverlay(
                message: 'Analyzing product & generating ideas...'),
        ],
      ),
    );
  }

  SliverToBoxAdapter _sectionHeader(
      String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _detailedCardList(List<IdeaVariant> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _DetailedCard(
            variant: items[index],
            onTap: () => _openDetail(items[index]),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  SliverPadding _compactCardList(List<IdeaVariant> items) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _CompactCard(
            variant: items[index],
            onTap: () => _openDetail(items[index]),
          ),
          childCount: items.length,
        ),
      ),
    );
  }
}

// ── Customer Truth Card ──────────────────────────────────────────────

class _CustomerTruthCard extends StatelessWidget {
  final CustomerTruth truth;

  const _CustomerTruthCard({required this.truth});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people_alt, color: AppColors.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'CUSTOMER TRUTH',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _truthRow('Buyer', truth.buyer),
          _truthRow('Job to be done', truth.jobToBeDone),
          if (truth.purchaseDrivers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Purchase Drivers',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: truth.purchaseDrivers
                  .map((d) => _pill(d, AppColors.primary))
                  .toList(),
            ),
          ],
          if (truth.complaints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Pain Points',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: truth.complaints
                  .map((c) => _pill(c, AppColors.error))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _truthRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.ink,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Detailed Card (Top Picks / Moonshot) ─────────────────────────────

class _DetailedCard extends StatelessWidget {
  final IdeaVariant variant;
  final VoidCallback onTap;

  const _DetailedCard({required this.variant, required this.onTap});

  Color get _accentColor =>
      variant.tier == 'moonshot' ? AppColors.purpleText : AppColors.primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.base),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: _accentColor.withValues(alpha: 0.1),
              ),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tier badge + title row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TierBadge(tier: variant.tier),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        variant.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.slateLight, size: 22),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // One-line pitch
                Text(
                  variant.summary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        height: 1.5,
                      ),
                ),

                // Target customer
                if (variant.targetCustomer != null &&
                    variant.targetCustomer!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: _accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          variant.targetCustomer!,
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Monetization
                if (variant.monetization != null &&
                    variant.monetization!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Icon(Icons.attach_money,
                          size: 16, color: AppColors.emeraldText),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          variant.monetization!,
                          style: TextStyle(
                            color: AppColors.emeraldText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Scores bar
                if (variant.scores != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _ScoresRow(scores: variant.scores!),
                ],

                // Why it wins
                if (variant.whyItWins.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  ...variant.whyItWins.take(3).map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle,
                                size: 14, color: _accentColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                reason,
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact Card (Upgrades / Adjacent / Recurring) ───────────────────

class _CompactCard extends StatelessWidget {
  final IdeaVariant variant;
  final VoidCallback onTap;

  const _CompactCard({required this.variant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                _TierBadge(tier: variant.tier, compact: true),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        variant.title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                      ),
                      if (variant.summary.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          variant.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.ink,
                                    height: 1.4,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: AppColors.slateLight, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tier Badge ───────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  final String tier;
  final bool compact;

  const _TierBadge({required this.tier, this.compact = false});

  (Color, Color, IconData) get _style {
    switch (tier) {
      case 'top':
        return (AppColors.primary, AppColors.primary, Icons.star);
      case 'moonshot':
        return (AppColors.purpleText, AppColors.purpleText, Icons.rocket_launch);
      case 'upgrade':
        return (AppColors.blueText, AppColors.blueText, Icons.trending_up);
      case 'adjacent':
        return (AppColors.teal, AppColors.teal, Icons.grid_view);
      case 'recurring':
        return (
          AppColors.emeraldText,
          AppColors.emeraldText,
          Icons.autorenew
        );
      default:
        return (AppColors.primary, AppColors.primary, Icons.lightbulb);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, _, icon) = _style;
    final size = compact ? 32.0 : 40.0;
    final iconSize = compact ? 16.0 : 20.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.lg),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

// ── Scores Row ───────────────────────────────────────────────────────

class _ScoresRow extends StatelessWidget {
  final IdeaScores scores;

  const _ScoresRow({required this.scores});

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
        final color = score >= 8
            ? AppColors.emeraldText
            : score >= 5
                ? AppColors.primary
                : AppColors.error;
        return Expanded(
          child: Column(
            children: [
              Text(
                '$score',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.slateLight,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
