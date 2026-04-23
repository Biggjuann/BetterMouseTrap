import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/credit_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/whiskers_widgets.dart';
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
      label: 'The Complaint',
      title: "What's broken?",
      subtitle:
          'A good product starts with a real grievance. What leaks, snaps, frustrates, or wastes time?',
      hint: 'e.g. "The lid never seals properly, it leaks in bags..."',
      required_: true,
    ),
    _WizardStep(
      label: 'The Person',
      title: 'Who needs this most?',
      subtitle:
          'Products sharpen around a specific user. Who would notice an improvement the most?',
      hint: 'e.g. "Busy parents who pack lunches every morning..."',
    ),
    _WizardStep(
      label: 'The Instinct',
      title: "What's your hypothesis?",
      subtitle:
          'Where does your intuition point? Jot it down — it shapes the angle we explore.',
      hint: 'e.g. "A magnetic seal system that\'s one-handed..."',
    ),
    _WizardStep(
      label: 'The Landscape',
      title: "What's already out there?",
      subtitle:
          'A quick scan of what exists helps us find the white space the incumbents miss.',
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
          duration: AppDuration.normal, curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: AppDuration.normal, curve: Curves.easeInOut);
    }
  }

  void _jumpTo(int i) {
    _pageController.animateToPage(i,
        duration: AppDuration.normal, curve: Curves.easeInOut);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Row(
                    children: [
                      IconBtn(
                          icon: Icons.arrow_back_rounded,
                          onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      Text('The Interview', style: AppText.sectionTitle),
                      const Spacer(),
                      const Mascot(pose: MascotPose.inventor, size: 36),
                    ],
                  ),
                ),

                // Product label
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Re: ${widget.productText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption
                        .copyWith(color: AppColors.inkSoft),
                  ),
                ),

                // Progress bar + step labels
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: (_currentPage + 1) / _steps.length,
                          minHeight: 5,
                          backgroundColor: AppColors.hairline,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.lav),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _StepTabs(
                        steps: _steps,
                        current: _currentPage,
                        onTap: _jumpTo,
                      ),
                    ],
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

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(step.label,
                  style: AppText.caption
                      .copyWith(color: AppColors.lavDark)),
              if (step.required_) ...[
                const SizedBox(width: 8),
                Pill('Required',
                    bg: AppColors.lav, fg: Colors.white),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(step.title, style: AppText.display2),
          const SizedBox(height: 8),
          Text(step.subtitle,
              style: AppText.bodyLg
                  .copyWith(color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 20),

          WCard(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: controller,
              maxLines: 7,
              minLines: 5,
              style: AppText.body
                  .copyWith(height: 1.55, color: AppColors.ink),
              cursorColor: AppColors.lav,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4),
                hintText: step.hint,
                hintMaxLines: 3,
                hintStyle: AppText.body.copyWith(
                    color: AppColors.inkSoft,
                    fontStyle: FontStyle.italic,
                    height: 1.5),
              ),
              onChanged: (_) => setState(() {}),
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
          SoftBtn(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            onPressed: _prevPage,
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        PrimaryBtn(
          label: 'Next',
          trailing: Icons.arrow_forward_rounded,
          onPressed: _nextPage,
        ),
      ],
    );
  }

  Widget _buildLastPageButtons() {
    return Column(
      children: [
        PrimaryBtn(
          label: 'Generate ideas',
          leading: Icons.auto_awesome_rounded,
          onPressed: _canGenerate ? _generate : null,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SoftBtn(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              onPressed: _prevPage,
            ),
            Pill('2 credits', bg: AppColors.lavLight, fg: AppColors.lavDark),
          ],
        ),
      ],
    );
  }
}

class _StepTabs extends StatelessWidget {
  final List<_WizardStep> steps;
  final int current;
  final ValueChanged<int> onTap;
  const _StepTabs(
      {required this.steps, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: steps.asMap().entries.map((e) {
        final active = e.key == current;
        final done = e.key < current;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTap(e.key),
            child: Padding(
              padding: EdgeInsets.only(right: e.key < steps.length - 1 ? 6 : 0),
              child: Text(
                e.value.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tiny.copyWith(
                  color: active
                      ? AppColors.lavDark
                      : done
                          ? AppColors.lav
                          : AppColors.inkSoft,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _WizardStep {
  final String label;
  final String title;
  final String subtitle;
  final String hint;
  final bool required_;

  const _WizardStep({
    required this.label,
    required this.title,
    required this.subtitle,
    required this.hint,
    this.required_ = false,
  });
}
