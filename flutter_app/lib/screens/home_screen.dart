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
          CustomScrollView(
            slivers: [
              // Hero gradient header
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppGradients.hero),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.base, AppSpacing.lg, AppSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          // Top bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.tips_and_updates,
                                size: 28,
                                color: Colors.white,
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.history, color: Colors.white),
                                    tooltip: 'My Ideas',
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const HistoryScreen(),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.logout, color: Colors.white),
                                    tooltip: 'Sign out',
                                    onPressed: _logout,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Hero text
                          Text(
                            'MouseTrap',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Got a product idea?\nLet\'s find out if it\'s a Hero or a Zero.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.4,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.base),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Form content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product input
                      Text(
                        'Describe your product',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: _urlController,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(
                          hintText: 'https://example.com/product',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Hero CTA button
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _canGenerate ? AppGradients.hero : null,
                          color: _canGenerate ? null : AppColors.lightWarmGray,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          boxShadow: _canGenerate
                              ? [
                                  BoxShadow(
                                    color: AppColors.primaryAmber
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _canGenerate
                                ? () => _generate(random: false)
                                : null,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_awesome,
                                    color: Colors.white, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Make it a Hero',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.primaryAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isLoading
                                ? null
                                : () => _generate(random: true),
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.casino_rounded,
                                    color: AppColors.primaryAmber, size: 22),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Surprise me!',
                                  style: TextStyle(
                                    color: AppColors.primaryAmber,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

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
