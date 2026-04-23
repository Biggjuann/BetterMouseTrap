import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/whiskers_widgets.dart';
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  // Progress dots
                  Row(
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: AppDuration.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == i ? 20 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? AppColors.lav
                            : AppColors.hairline,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                      ),
                    )),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text('Skip',
                        style: AppText.caption.copyWith(
                            color: AppColors.inkSoft)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(20, 8, 20, AppSpacing.xl),
              child: _currentPage == 2
                  ? PrimaryBtn(
                      label: 'Enter the Workshop',
                      trailing: Icons.arrow_forward_rounded,
                      onPressed: _completeOnboarding,
                    )
                  : PrimaryBtn(
                      label: 'Next',
                      trailing: Icons.arrow_forward_rounded,
                      onPressed: _nextPage,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(pose: MascotPose.ideabox, size: 160),
          const SizedBox(height: 24),
          Text('A Quiet Place\nto Invent.',
              style: AppText.display1, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Name any product. MouseTrap writes back with seven invention angles — tiered, scored, patent-aware.',
            style: AppText.bodyLg.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.lavLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded,
                    color: AppColors.lav, size: 18),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: AppText.body.copyWith(
                        color: AppColors.lavDark),
                    children: const [
                      TextSpan(
                          text: '5 free credits ',
                          style:
                              TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: 'on arrival.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage2() {
    const steps = [
      ('💬', 'Describe the product',
          'Type a name or paste a reference URL.'),
      ('⚡', 'Receive the brief',
          'Seven angles, tiered and scored, within a minute.'),
      ('🔍', 'Weigh the prior art',
          'We read the patent ledger for you.'),
      ('📄', 'Export the one-pager',
          'PDF ready to email, print, or pin up.'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(pose: MascotPose.detective, size: 120),
          const SizedBox(height: 20),
          Text('Four Movements.',
              style: AppText.display1, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ...steps.map((s) {
            final (emoji, title, body) = s;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.lavLight,
                      borderRadius:
                          BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 17))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppText.bodyBold),
                        Text(body,
                            style: AppText.caption),
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

  Widget _buildPage3() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Mascot(pose: MascotPose.hero, size: 160),
          const SizedBox(height: 24),
          Text('Ready to Build?',
              style: AppText.display1, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Your first idea is sixty seconds away. Be specific — hero products earn the best briefs.',
            style: AppText.bodyLg.copyWith(color: AppColors.inkSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          WCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFC4B5FD), AppColors.lav],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Text(
              '"The bottle is the moat. Refill models quietly make incumbents look disposable."',
              style: AppText.body.copyWith(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
