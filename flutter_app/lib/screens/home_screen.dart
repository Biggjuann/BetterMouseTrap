import 'package:flutter/material.dart';

import '../models/api_responses.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/credit_service.dart';
import '../services/purchase_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
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
  String _insightText = '';
  bool _insightLoading = true;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.onUnauthorized = _goToLogin;
    CreditService.instance.refresh();
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
        _insightText = 'Sustainable packaging is trending in the luxury cosmetics sector. Refill models are creating built-in recurring revenue for scrappy consumer brands.';
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 24),
            SizedBox(width: AppSpacing.sm),
            Text(
              'Delete Account?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete your account, all your saved ideas, and credit balance. This cannot be undone.',
          style: TextStyle(color: AppColors.ink, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Top bar — credits + history + logout
                    Row(
                      children: [
                        // Credit balance pill
                        ValueListenableBuilder<int>(
                          valueListenable: CreditService.instance.balance,
                          builder: (context, balance, _) {
                            final isAdmin = CreditService.instance.isAdmin.value;
                            return GestureDetector(
                              onTap: () => _showBuyCreditsSheet(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.toll, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      isAdmin ? 'Unlimited' : '$balance',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.history_rounded, color: AppColors.primary),
                          tooltip: 'My Ideas',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert_rounded, color: AppColors.mist),
                          onSelected: (value) {
                            if (value == 'logout') _logout();
                            if (value == 'delete') _deleteAccount();
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'logout',
                              child: Row(
                                children: [
                                  Icon(Icons.logout_rounded, size: 20, color: AppColors.ink),
                                  SizedBox(width: AppSpacing.sm),
                                  Text('Sign out'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever, size: 20, color: AppColors.coral),
                                  SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Delete account',
                                    style: TextStyle(color: AppColors.coral),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Hero icon — Stitch: rotated bg + icon
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Transform.rotate(
                              angle: 0.1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(AppRadius.xl),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(AppRadius.xl),
                                boxShadow: AppShadows.button,
                              ),
                              child: const Icon(
                                Icons.precision_manufacturing,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Title — Stitch: "Mouse<primary>Trap</primary>"
                    RichText(
                      text: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ).let((s) => TextSpan(
                        children: [
                          TextSpan(text: 'Mouse', style: s),
                          TextSpan(
                            text: 'Trap',
                            style: s.copyWith(color: AppColors.primary),
                          ),
                        ],
                      )),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Subtitle
                    Text(
                      'Turn any product into your\nnext big idea.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Search input — Stitch: icon + rounded-xl
                    TextField(
                      controller: _productController,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                        hintText: 'Enter a product name...',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.base),

                    // URL input
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.link_rounded,
                          color: AppColors.mist,
                        ),
                        hintText: 'Product URL (optional)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Primary CTA — Stitch: bg-primary, white, rounded-xl, shadow
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          boxShadow: _canGenerate ? AppShadows.button : [],
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                        child: FilledButton(
                          onPressed: _canGenerate
                              ? () => _generate(random: false)
                              : null,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('Make it a Hero'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Secondary CTA — "Surprise Me"
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : () => _generate(random: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text('Surprise Me'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Quick action row — 2 items: Recent Ideas + Market Trends
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickAction(
                          icon: Icons.history,
                          label: 'Recent\nIdeas',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                        _QuickAction(
                          icon: Icons.lightbulb,
                          label: 'Market\nTrends',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MarketTrendsScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Today's Insight card — Stitch
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "TODAY'S INSIGHT",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
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
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Loading fresh insight...',
                                  style: TextStyle(
                                    color: AppColors.mist,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else
                            Text(
                              _insightText,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Disclaimer
                    const DisclaimerBanner(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(
                message: 'Finding your next hero product...'),
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

  Future<void> _generate({required bool random}) async {
    // Credit gate
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

      // Deduct credit locally after success
      CreditService.instance.localDeduct();

      // Create session and save variants
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
      } catch (_) {
        // Session save failure shouldn't block the flow
      }

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

// Quick action circle — Stitch design
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to use TextStyle as TextSpan parent
extension _TextStyleExt on TextStyle {
  TextSpan let(TextSpan Function(TextStyle) fn) => fn(this);
}
