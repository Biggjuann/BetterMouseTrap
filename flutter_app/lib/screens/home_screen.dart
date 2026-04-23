import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/whiskers_widgets.dart';
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
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text('Delete account?', style: AppText.display3),
        content: Text(
          'This will permanently delete your account, all your saved ideas, and credit balance. This cannot be undone.',
          style: AppText.body.copyWith(color: AppColors.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ────────────────────────────────────────
                  _TopBar(
                    onHistory: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const HistoryScreen())),
                    onBuyCredits: _showBuyCreditsSheet,
                    onLogout: _logout,
                    onDelete: _deleteAccount,
                  ),
                  const SizedBox(height: 18),

                  // ── Hero headline ──────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Build the next\nbig thing. 🚀',
                                style: AppText.display1),
                            const SizedBox(height: 4),
                            Text(
                              'Name any product — get 7 invention angles.',
                              style: AppText.caption,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                            color: AppColors.lavLight,
                            shape: BoxShape.circle),
                        child: const Center(
                            child: Mascot(
                                pose: MascotPose.cheese, size: 46)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Input card ─────────────────────────────────────
                  WCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start something new', style: AppText.display3),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _productController,
                          onChanged: (_) => setState(() {}),
                          style: AppText.bodyLg,
                          decoration: InputDecoration(
                            hintText: 'e.g. All-purpose spray cleaner',
                            hintStyle: AppText.bodyLg
                                .copyWith(color: AppColors.inkSoft),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _urlController,
                          keyboardType: TextInputType.url,
                          style: AppText.body,
                          decoration: InputDecoration(
                            hintText: 'Reference URL (optional)',
                            hintStyle: AppText.body
                                .copyWith(color: AppColors.inkSoft),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Mode toggle
                        Row(
                          children: [
                            Expanded(
                              child: _ModeChip(
                                label: '⚡ Quick',
                                sub: '1 credit · ~60s',
                                selected: !_guidedMode,
                                onTap: () =>
                                    setState(() => _guidedMode = false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _ModeChip(
                                label: '📋 Guided',
                                sub: '2 credits · ~4 min',
                                selected: _guidedMode,
                                onTap: () =>
                                    setState(() => _guidedMode = true),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        PrimaryBtn(
                          label: _guidedMode
                              ? 'Begin Interview'
                              : 'Generate Ideas',
                          trailing: _guidedMode
                              ? Icons.auto_stories_rounded
                              : Icons.auto_awesome_rounded,
                          loading: _isLoading,
                          onPressed: _canGenerate
                              ? () => _guidedMode
                                  ? _startGuided()
                                  : _generate(random: false)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: SoftBtn(
                            label: 'Surprise me 🎲',
                            bg: AppColors.sunBg,
                            fg: AppColors.warn,
                            onPressed: _isLoading
                                ? null
                                : () => _generate(random: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Quick Actions grid ─────────────────────────────
                  const SectionHeader('Quick Actions'),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: [
                      _QuickAction(
                          emoji: '📁',
                          label: 'My Projects',
                          bg: AppColors.mintBg,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HistoryScreen()))),
                      _QuickAction(
                          emoji: '📈',
                          label: 'Market Trends',
                          bg: AppColors.lavLight,
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MarketTrendsScreen()))),
                      _QuickAction(
                          emoji: '💳',
                          label: 'Buy Credits',
                          bg: AppColors.sunBg,
                          onTap: _showBuyCreditsSheet),
                      _QuickAction(
                          emoji: '🧙',
                          label: 'Guided Wizard',
                          bg: AppColors.peachBg,
                          onTap: () {
                            if (_productController.text.trim().isNotEmpty) {
                              _startGuided();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Enter a product name first.')),
                              );
                            }
                          }),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Today's insight ────────────────────────────────
                  const SectionHeader('Today\'s Insight'),
                  WCard(
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
                            const Mascot(
                                pose: MascotPose.inventor, size: 36),
                            const SizedBox(width: 10),
                            Text('Whiskers says…',
                                style: AppText.caption
                                    .copyWith(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_insightLoading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else
                          Text(
                            '"$_insightText"',
                            style: AppText.bodyLg.copyWith(
                                color: Colors.white,
                                fontStyle: FontStyle.italic,
                                height: 1.5),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

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
}

// ── Top bar ──────────────────────────────────────────────────────────
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
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), AppColors.lav],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.memory_rounded,
              color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MOUSETRAP',
                  style: AppText.bodyBold
                      .copyWith(letterSpacing: 1.5)),
              Text('Invention Engine',
                  style: AppText.tiny),
            ],
          ),
        ),
        // Credits pill
        ValueListenableBuilder<int>(
          valueListenable: CreditService.instance.balance,
          builder: (context, balance, _) {
            final isAdmin = CreditService.instance.isAdmin.value;
            return GestureDetector(
              onTap: onBuyCredits,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.lavLight,
                  borderRadius:
                      BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.lav),
                    const SizedBox(width: 4),
                    Text(
                      isAdmin ? '∞' : '$balance',
                      style: AppText.bodyBold
                          .copyWith(color: AppColors.lavDark),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        IconBtn(
            icon: Icons.history_rounded, onPressed: onHistory),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: IconBtn(
              icon: Icons.more_horiz_rounded, onPressed: null),
          color: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md)),
          onSelected: (v) {
            if (v == 'logout') onLogout();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.ink),
                const SizedBox(width: 10),
                Text('Sign out', style: AppText.body),
              ]),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(children: [
                const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.danger),
                const SizedBox(width: 10),
                Text('Delete account',
                    style: AppText.body
                        .copyWith(color: AppColors.danger)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Mode chip ────────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;
  const _ModeChip(
      {required this.label,
      required this.sub,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.lavLight : AppColors.bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color:
                  selected ? AppColors.lav : AppColors.hairline,
              width: selected ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppText.bodyBold.copyWith(
                    color: selected
                        ? AppColors.lavDark
                        : AppColors.ink)),
            Text(sub,
                style: AppText.tiny.copyWith(
                    color: selected
                        ? AppColors.lav
                        : AppColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

// ── Quick action tile ────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final String emoji;
  final String label;
  final Color bg;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.emoji,
      required this.label,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.sm)),
            alignment: Alignment.center,
            child: Text(emoji,
                style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label,
                style: AppText.body
                    .copyWith(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
