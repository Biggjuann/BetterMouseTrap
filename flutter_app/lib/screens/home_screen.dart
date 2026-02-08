import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/disclaimer_banner.dart';
import '../widgets/loading_overlay.dart';
import 'history_screen.dart';
import 'ideas_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _productController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ApiClient.instance.onUnauthorized = _goToLogin;
  }

  @override
  void dispose() {
    _productController.dispose();
    _urlController.dispose();
    super.dispose();
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
    _goToLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Subtle page gradient (Calm-style)
          Container(
            decoration: const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          CustomScrollView(
            slivers: [
              // Hero header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppGradients.hero,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppRadius.xl),
                      bottomRight: Radius.circular(AppRadius.xl),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xxl,
                      ),
                      child: Column(
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.tips_and_updates_outlined,
                                size: 26,
                                color: Colors.white,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history_rounded, color: Colors.white),
                                    tooltip: 'My Ideas',
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HistoryScreen(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                                    tooltip: 'Sign out',
                                    onPressed: _logout,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xxl),

                          // Hero text — Calm-style generous spacing
                          Text(
                            'MouseTrap',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Got a product idea?\nLet\'s find out if it\'s a Hero or a Zero.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.5,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Form content — Calm generous spacing
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product input
                      Text(
                        'Describe your product',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _productController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. "travel coffee mug", "shower caddy", "bike lock"',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // URL input
                      Text(
                        'Product URL (optional)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://example.com/product',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Hero CTA — dark pill button (Etsy)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _canGenerate
                              ? () => _generate(random: false)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: _canGenerate
                                ? AppColors.ink
                                : AppColors.mist,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.auto_awesome, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text(
                                'Make it a Hero',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Secondary CTA — outlined pill
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _generate(random: true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.casino_rounded,
                                  size: 20, color: AppColors.amber),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                'Surprise me!',
                                style: TextStyle(
                                  color: AppColors.amber,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      const DisclaimerBanner(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
            ],
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

  Future<void> _generate({required bool random}) async {
    setState(() => _isLoading = true);
    try {
      final text = random ? '' : _productController.text.trim();
      final productUrl = _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim();

      final variants = await ApiClient.instance.generateIdeas(
        text: text,
        random: random,
      );

      // Create session and save variants
      String? sessionId;
      try {
        final sessionData = await ApiClient.instance.createSession(
          productText: _productController.text.trim(),
          productUrl: productUrl,
        );
        sessionId = sessionData['id'] as String;
        await ApiClient.instance.updateSession(sessionId, {
          'variants_json': variants.map((v) => v.toJson()).toList(),
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
            variants: variants,
            productText: _productController.text.trim(),
            productURL: productUrl,
            sessionId: sessionId,
            random: random,
          ),
        ),
      );
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
