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

                    // Top bar — history + logout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history_rounded, color: AppColors.primary),
                          tooltip: 'My Ideas',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.mist),
                          tooltip: 'Sign out',
                          onPressed: _logout,
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
                        color: AppColors.ink.withValues(alpha: 0.7),
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

                    // Quick action row — Stitch: 3 circles with labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _QuickAction(
                          icon: Icons.analytics,
                          label: 'Patent\nAnalysis',
                          onTap: () {},
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
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
                          onTap: () {},
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
                          Text(
                            'Sustainable packaging is trending in the luxury cosmetics sector. Tap to explore.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
