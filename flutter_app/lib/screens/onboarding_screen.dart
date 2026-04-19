import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/studio_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await AuthService.instance.markOnboardingSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: AppDuration.normal,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Text(
                    '0${_currentPage + 1} / 03',
                    style: TextStyle(
                      fontFamily: fontMono,
                      fontSize: 10,
                      letterSpacing: 2,
                      color: AppColors.mist,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: fontMono,
                        fontSize: 10,
                        letterSpacing: 2,
                        color: AppColors.graphite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildHowItWorksPage(),
                  _buildReadyPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.base),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: AppDuration.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 18 : 6,
                  height: 2,
                  decoration: BoxDecoration(
                    color: _currentPage == i ? AppColors.ink : AppColors.border,
                  ),
                )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
              child: _currentPage == 2
                  ? StudioButton(
                      label: 'Enter the workshop',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _completeOnboarding,
                    )
                  : StudioButton(
                      label: 'Continue',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Eyebrow('Chapter one · the premise'),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: AppText.display1,
              children: [
                const TextSpan(text: 'A quiet place\nto '),
                TextSpan(
                  text: 'invent.',
                  style: AppText.display1.copyWith(
                    fontStyle: FontStyle.italic,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Name any product. MouseTrap writes back with seven invention angles — tiered by ambition, scored by evidence, patent-aware.',
            style: AppText.bodyLg.copyWith(color: AppColors.graphite),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(Icons.star_border_rounded, color: AppColors.accentInk, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppText.body.copyWith(color: AppColors.accentInk),
                      children: [
                        const TextSpan(
                          text: 'Five credits on arrival. ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const TextSpan(text: 'Spend them on ideas.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage() {
    const steps = [
      ('A.', 'Describe the product', 'Type a name or paste a reference url.'),
      ('B.', 'Receive the brief', 'Seven angles, tiered and scored, within a minute.'),
      ('C.', 'Weigh the prior art', 'We read the patent ledger for you.'),
      ('D.', 'Export the one-pager', 'PDF ready to email, print, or pin up.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Eyebrow('Chapter two · the method'),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: AppText.display1,
              children: [
                const TextSpan(text: 'Four\n'),
                TextSpan(
                  text: 'movements.',
                  style: AppText.display1.copyWith(fontStyle: FontStyle.italic, color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ...steps.map((s) {
            final (marker, title, body) = s;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      marker,
                      style: TextStyle(
                        fontFamily: fontMono,
                        fontSize: 12,
                        color: AppColors.mist,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.display4),
                        const SizedBox(height: 3),
                        Text(body, style: AppText.bodySm),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildReadyPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Eyebrow('Chapter three · begin'),
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: AppText.display1,
              children: [
                const TextSpan(text: 'The desk is\n'),
                TextSpan(
                  text: 'ready.',
                  style: AppText.display1.copyWith(fontStyle: FontStyle.italic, color: AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Your first idea is sixty seconds away. Be specific — hero products earn the best briefs.',
            style: AppText.bodyLg.copyWith(color: AppColors.graphite),
          ),
          const SizedBox(height: AppSpacing.xl),
          StudioCard(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '"The bottle is the moat. Refill models quietly make incumbents look disposable."',
                    style: AppText.display4.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Today\'s dispatch', style: AppText.monoMeta),
        ],
      ),
    );
  }
}
