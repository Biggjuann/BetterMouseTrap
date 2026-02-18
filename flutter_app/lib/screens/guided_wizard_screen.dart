import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/credit_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/loading_overlay.dart';
import 'ideas_list_screen.dart';

class GuidedWizardScreen extends StatefulWidget {
  final String productText;
  final String? productUrl;

  const GuidedWizardScreen({
    super.key,
    required this.productText,
    this.productUrl,
  });

  @override
  State<GuidedWizardScreen> createState() => _GuidedWizardScreenState();
}

class _GuidedWizardScreenState extends State<GuidedWizardScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  final _painPointsController = TextEditingController();
  final _targetCustomerController = TextEditingController();
  final _hypothesisController = TextEditingController();
  final _marketContextController = TextEditingController();

  static const _steps = [
    _WizardStep(
      icon: Icons.report_problem_outlined,
      title: "What's broken?",
      subtitle:
          'A great product starts with a real problem. What frustrations or limitations have you noticed?',
      hint: 'e.g. "The lid never seals properly, it leaks in bags..."',
    ),
    _WizardStep(
      icon: Icons.people_outline,
      title: 'Who needs this most?',
      subtitle:
          'The best products serve a specific customer. Who would benefit most from an improvement?',
      hint: 'e.g. "Busy parents who pack lunches every morning..."',
    ),
    _WizardStep(
      icon: Icons.lightbulb_outline,
      title: "What's your instinct?",
      subtitle:
          'Great consultants start with a hypothesis. What improvements or directions excite you?',
      hint: 'e.g. "A magnetic seal system that\'s one-handed..."',
    ),
    _WizardStep(
      icon: Icons.landscape_outlined,
      title: "What's out there?",
      subtitle:
          'Understanding the landscape helps find white space. What alternatives exist? What\'s missing?',
      hint: 'e.g. "Yeti and Stanley dominate but they\'re all screw-top..."',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _painPointsController.dispose();
    _targetCustomerController.dispose();
    _hypothesisController.dispose();
    _marketContextController.dispose();
    super.dispose();
  }

  TextEditingController _controllerForStep(int step) {
    switch (step) {
      case 0:
        return _painPointsController;
      case 1:
        return _targetCustomerController;
      case 2:
        return _hypothesisController;
      case 3:
        return _marketContextController;
      default:
        return _painPointsController;
    }
  }

  bool get _canGenerate => _painPointsController.text.trim().isNotEmpty;

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: AppDuration.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDuration.normal,
        curve: Curves.easeInOut,
      );
    }
  }

  void _showBuyCreditsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BuyCreditsSheet(),
    );
  }

  Future<void> _generate() async {
    if (!CreditService.instance.hasCreditsFor(2)) {
      _showBuyCreditsSheet();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final guidedContext = <String, String>{};
      if (_painPointsController.text.trim().isNotEmpty) {
        guidedContext['pain_points'] = _painPointsController.text.trim();
      }
      if (_targetCustomerController.text.trim().isNotEmpty) {
        guidedContext['target_customer'] =
            _targetCustomerController.text.trim();
      }
      if (_hypothesisController.text.trim().isNotEmpty) {
        guidedContext['hypothesis'] = _hypothesisController.text.trim();
      }
      if (_marketContextController.text.trim().isNotEmpty) {
        guidedContext['market_context'] =
            _marketContextController.text.trim();
      }

      final response = await ApiClient.instance.generateIdeas(
        text: widget.productText,
        guidedContext: guidedContext,
      );

      CreditService.instance.localDeduct(2);

      // Create session and save variants
      String? sessionId;
      try {
        final sessionData = await ApiClient.instance.createSession(
          productText: widget.productText,
          productUrl: widget.productUrl,
        );
        sessionId = sessionData['id'] as String;
        await ApiClient.instance.updateSession(sessionId, {
          'variants_json':
              response.variants.map((v) => v.toJson()).toList(),
          'status': 'ideas_generated',
        });
      } catch (_) {}

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IdeasListScreen(
            variants: response.variants,
            customerTruth: response.customerTruth,
            productText: widget.productText,
            productURL: widget.productUrl,
            sessionId: sessionId,
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
      body: Stack(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.pageBackground),
          ),
          SafeArea(
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new,
                            size: 20, color: AppColors.ink),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.productText,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance the back button
                    ],
                  ),
                ),

                // Progress dots
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.base),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (i) => AnimatedContainer(
                        duration: AppDuration.fast,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) =>
                        setState(() => _currentPage = i),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      final controller = _controllerForStep(index);
                      return _buildStepPage(step, controller);
                    },
                  ),
                ),

                // Bottom navigation
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.base,
                    AppSpacing.xl,
                    AppSpacing.xxl,
                  ),
                  child: _currentPage == _steps.length - 1
                      ? _buildLastPageButtons()
                      : _buildNavButtons(),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LoadingOverlay(
                message: 'Crafting your personalized ideas...'),
        ],
      ),
    );
  }

  Widget _buildStepPage(_WizardStep step, TextEditingController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(step.icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            step.subtitle,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.6),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Text field
          TextField(
            controller: controller,
            maxLines: 6,
            minLines: 4,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.ink,
              height: 1.5,
            ),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.cardWhite,
              hintText: step.hint,
              hintMaxLines: 3,
              alignLabelWithHint: true,
              hintStyle: TextStyle(
                color: AppColors.ink.withValues(alpha: 0.3),
                fontSize: 15,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: Text(
              'Step ${_currentPage + 1} of ${_steps.length}${_currentPage == 0 ? '  (required)' : '  (optional)'}',
              style: TextStyle(
                color: AppColors.mist,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButtons() {
    return Row(
      children: [
        if (_currentPage > 0)
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: _prevPage,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Text('Back'),
                ],
              ),
            ),
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: _nextPage,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Next'),
                SizedBox(width: AppSpacing.xs),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLastPageButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              boxShadow: _canGenerate ? AppShadows.button : [],
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: FilledButton(
              onPressed: _canGenerate ? _generate : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Text('Generate Ideas'),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _prevPage,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18),
                  SizedBox(width: AppSpacing.xs),
                  Text('Back'),
                ],
              ),
            ),
            Text(
              '2 credits',
              style: TextStyle(
                color: AppColors.mist,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WizardStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;

  const _WizardStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
  });
}
