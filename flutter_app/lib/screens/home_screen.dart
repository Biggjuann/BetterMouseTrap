import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/studio_widgets.dart';
import 'guided_wizard_screen.dart';
import 'history_screen.dart';
import 'ideas_list_screen.dart';
import 'login_screen.dart';
import 'market_trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  bool _guidedMode = false;
  String _insightText = '';
  bool _insightLoading = true;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.onUnauthorized = _goToLogin;
    CreditService.instance.refresh();
    PurchaseService.instance.init();
    _loadInsight();
  }

  @override
  void dispose() {
    _productController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadInsight() async {
    try {
      final insight = await ApiClient.instance.getDailyInsight();
      if (!mounted) return;
      setState(() {
        _insightText = insight;
        _insightLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _insightText =
            'The bottle is the moat. Refill models quietly make incumbents look disposable.';
        _insightLoading = false;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    CreditService.instance.reset();
    _goToLogin();
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.hairline),
        ),
        title: Text('Delete account?', style: AppText.display4),
        content: const Text(
          'This will permanently delete your account, all your saved ideas, and credit balance. This cannot be undone.',
          style: TextStyle(
            fontFamily: fontSans,
            color: AppColors.graphite,
            height: 1.55,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warm,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.deleteAccount();
      CreditService.instance.reset();
      if (!mounted) return;
      _goToLogin();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(
                    onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                    onBuyCredits: _showBuyCreditsSheet,
                    onLogout: _logout,
                    onDelete: _deleteAccount,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Editorial hero ──────────────────────────────
                  const Eyebrow('File Nº 0048 · an inventor\'s tool'),
                  const SizedBox(height: AppSpacing.md),
                  RichText(
                    text: TextSpan(
                      style: AppText.display1,
                      children: [
                        const TextSpan(text: 'Build a '),
                        TextSpan(
                          text: 'better\n',
                          style: AppText.display1.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.accent,
                          ),
                        ),
                        const TextSpan(text: 'mousetrap.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.base),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 28, height: 1, margin: const EdgeInsets.only(top: 10, right: 12), color: AppColors.ink),
                      Expanded(
                        child: Text(
                          'Name any product. Leave with seven invention angles — tiered, scored, patent-aware.',
                          style: AppText.bodyLg.copyWith(color: AppColors.graphite),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // ── Specimen form ───────────────────────────────
                  _SpecimenForm(
                    productController: _productController,
                    urlController: _urlController,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.base),

                  // ── Mode toggle — Quick / Guided cards ──────────
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          title: 'Quick',
                          subtitle: '1 CREDIT · 60S',
                          selected: !_guidedMode,
                          onTap: () => setState(() => _guidedMode = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ModeCard(
                          title: 'Guided',
                          subtitle: '2 CREDITS · 4 MIN',
                          selected: _guidedMode,
                          onTap: () => setState(() => _guidedMode = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Primary CTA ─────────────────────────────────
                  StudioButton(
                    label: _guidedMode ? 'Begin interview' : 'Generate ideas',
                    icon: _guidedMode ? Icons.auto_stories_rounded : Icons.auto_awesome_rounded,
                    onPressed: _canGenerate
                        ? () => _guidedMode
                            ? _startGuided()
                            : _generate(random: false)
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  StudioButton(
                    label: 'Surprise me',
                    kind: BtnKind.ghost,
                    large: false,
                    onPressed: _isLoading ? null : () => _generate(random: true),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Dispatch card — today's insight ─────────────
                  StudioCard(
                    background: AppColors.accentSoft,
                    border: Border.all(color: Colors.transparent),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Eyebrow(
                                'Dispatch · today',
                                color: AppColors.accentInk,
                              ),
                            ),
                            Text(
                              '06:00 PT',
                              style: AppText.monoMeta,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (_insightLoading)
                          Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accentInk,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Loading fresh insight…',
                                style: AppText.bodySm,
                              ),
                            ],
                          )
                        else
                          _PullQuote(text: _insightText),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Index — navigational ledger ─────────────────
                  _LedgerRow(
                    title: 'Archive of past sessions',
                    trailing: 'Open',
                    isFirst: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  _LedgerRow(
                    title: 'Weekly market dispatch',
                    trailing: 'Read',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MarketTrendsScreen()),
                    ),
                  ),
                  _LedgerRow(
                    title: 'Credits & account',
                    trailing: 'Manage',
                    onTap: _showBuyCreditsSheet,
                    isLast: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const DisclaimerBanner(),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(
              message: 'Finding your next hero product…',
            ),
        ],
      ),
    );
  }

  bool get _canGenerate =>
      !_isLoading && _productController.text.trim().isNotEmpty;

  void _showBuyCreditsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuyCreditsSheet(),
    );
  }

  void _startGuided() {
    if (!CreditService.instance.hasCreditsFor(2)) {
      _showBuyCreditsSheet();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedWizardScreen(
          productText: _productController.text.trim(),
          productUrl: _urlController.text.trim().isEmpty
              ? null
              : _urlController.text.trim(),
        ),
      ),
    );
  }

  Future<void> _generate({required bool random}) async {
    if (!CreditService.instance.hasCredits) {
      _showBuyCreditsSheet();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final text = random ? '' : _productController.text.trim();
      final productUrl = _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim();

      final response = await ApiClient.instance.generateIdeas(
        text: text,
        random: random,
      );

      CreditService.instance.localDeduct();

      String? sessionId;
      try {
        final sessionData = await ApiClient.instance.createSession(
          productText: _productController.text.trim(),
          productUrl: productUrl,
        );
        sessionId = sessionData['id'] as String;
        await ApiClient.instance.updateSession(sessionId, {
          'variants_json': response.variants.map((v) => v.toJson()).toList(),
          'status': 'ideas_generated',
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IdeasListScreen(
            variants: response.variants,
            customerTruth: response.customerTruth,
            productText: _productController.text.trim(),
            productURL: productUrl,
            sessionId: sessionId,
            random: random,
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
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ── Top bar: credits pill + history + menu ──────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onBuyCredits;
  final VoidCallback onLogout;
  final VoidCallback onDelete;

  const _TopBar({
    required this.onHistory,
    required this.onBuyCredits,
    required this.onLogout,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Brand mark
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.memory_rounded, color: AppColors.canvas, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOUSE·TRAP',
                style: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Studio · Vol. II',
                style: AppText.monoMeta,
              ),
            ],
          ),
        ),
        ValueListenableBuilder<int>(
          valueListenable: CreditService.instance.balance,
          builder: (context, balance, _) {
            final isAdmin = CreditService.instance.isAdmin.value;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBuyCredits,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_border_rounded, size: 14, color: AppColors.warm),
                      const SizedBox(width: 4),
                      Text(
                        isAdmin ? '∞' : '$balance',
                        style: TextStyle(
                          fontFamily: fontMono,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconBtn(
          icon: Icons.history_rounded,
          onPressed: onHistory,
        ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: IconBtn(icon: Icons.more_horiz_rounded, onPressed: null),
          color: AppColors.canvas,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: AppColors.hairline),
          ),
          onSelected: (value) {
            if (value == 'logout') onLogout();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                Icon(Icons.logout_rounded, size: 18, color: AppColors.ink),
                SizedBox(width: 10),
                Text('Sign out', style: TextStyle(fontFamily: fontSans, fontSize: 13, color: AppColors.ink)),
              ]),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.warm),
                SizedBox(width: 10),
                Text('Delete account', style: TextStyle(fontFamily: fontSans, fontSize: 13, color: AppColors.warm)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Specimen form — labelled inputs, paper-form aesthetic ───────────
class _SpecimenForm extends StatelessWidget {
  final TextEditingController productController;
  final TextEditingController urlController;
  final VoidCallback onChanged;

  const _SpecimenForm({
    required this.productController,
    required this.urlController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.9)),
      ),
      child: Column(
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
            ),
            child: Row(
              children: [
                Text(
                  'SPECIMEN',
                  style: TextStyle(
                    fontFamily: fontMono,
                    fontSize: 10,
                    color: AppColors.canvas,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '01 / 02',
                  style: TextStyle(
                    fontFamily: fontMono,
                    fontSize: 10,
                    color: AppColors.canvas,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Row A — product
          _FormRow(
            marker: 'A.',
            child: TextField(
              controller: productController,
              onChanged: (_) => onChanged(),
              style: AppText.display4.copyWith(color: AppColors.ink),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'All-purpose spray cleaner',
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppColors.hairline, indent: 14, endIndent: 14),
          // Row B — url
          _FormRow(
            marker: 'B.',
            child: TextField(
              controller: urlController,
              keyboardType: TextInputType.url,
              style: TextStyle(
                fontFamily: fontMono,
                fontSize: 12.5,
                color: AppColors.ink,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'reference url (optional)',
                hintStyle: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 12.5,
                  color: AppColors.mist,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormRow extends StatelessWidget {
  final String marker;
  final Widget child;

  const _FormRow({required this.marker, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 22,
            child: Text(
              marker,
              style: TextStyle(
                fontFamily: fontMono,
                fontSize: 10,
                color: AppColors.mist,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Mode card — Quick vs Guided ─────────────────────────────────────
class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: AppDuration.fast,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.canvas,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.hairline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppText.display4.copyWith(
                        color: selected ? AppColors.canvas : AppColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.canvas : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: selected
                        ? Center(
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.canvas,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: fontMono,
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? AppColors.canvas.withValues(alpha: 0.7)
                      : AppColors.mist,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pull-quote — display-italic block used for insights ─────────────
class _PullQuote extends StatelessWidget {
  final String text;
  const _PullQuote({required this.text});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: AppText.display4.copyWith(
          color: AppColors.ink,
          height: 1.25,
        ),
        children: [
          TextSpan(
            text: '"',
            style: AppText.display4.copyWith(fontStyle: FontStyle.italic),
          ),
          TextSpan(
            text: text,
            style: AppText.display4.copyWith(fontStyle: FontStyle.italic, color: AppColors.ink),
          ),
          TextSpan(
            text: '"',
            style: AppText.display4.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ── Ledger row — index list-item with hairline rule ─────────────────
class _LedgerRow extends StatelessWidget {
  final String title;
  final String trailing;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  const _LedgerRow({
    required this.title,
    required this.trailing,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: isFirst ? const BorderSide(color: AppColors.hairline) : BorderSide.none,
          bottom: const BorderSide(color: AppColors.hairline),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(title, style: AppText.display4),
                ),
                Text(
                  trailing,
                  style: AppText.monoMeta,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
