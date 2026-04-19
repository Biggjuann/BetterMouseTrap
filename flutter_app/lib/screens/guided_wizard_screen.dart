import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/credit_service.dart';
import '../theme.dart';
import '../widgets/buy_credits_sheet.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/studio_widgets.dart';
import 'ideas_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────
// Guided Wizard — The Interview
//
// Four-card interview. Each "card" is a labelled field with a serif
// prompt and an Inter subprompt. Progress is rendered as a file-tab
// strip (01 / 02 / 03 / 04) so the wizard reads as chapters in a
// dossier rather than a modal slideshow. Footer sticks with
// StudioButton primary + ghost.
// ─────────────────────────────────────────────────────────────────────

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
      eyebrow: 'CHAPTER 01 · THE COMPLAINT',
      title: "What's broken?",
      subtitle:
          'A good product starts with a real grievance. What leaks, snaps, frustrates, or wastes time?',
      hint: 'e.g. "The lid never seals properly, it leaks in bags..."',
      required_: true,
    ),
    _WizardStep(
      eyebrow: 'CHAPTER 02 · THE PERSON',
      title: 'Who needs this most?',
      subtitle:
          'Products sharpen around a specific user. Who would notice an improvement the most?',
      hint: 'e.g. "Busy parents who pack lunches every morning..."',
    ),
    _WizardStep(
      eyebrow: 'CHAPTER 03 · THE INSTINCT',
      title: "What's your hypothesis?",
      subtitle:
          'Where does your intuition point? Jot it down — it shapes the angle we explore.',
      hint: 'e.g. "A magnetic seal system that\'s one-handed..."',
    ),
    _WizardStep(
      eyebrow: 'CHAPTER 04 · THE LANDSCAPE',
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
      case 0: return _painPointsController;
      case 1: return _targetCustomerController;
      case 2: return _hypothesisController;
      case 3: return _marketContextController;
      default: return _painPointsController;
    }
  }

  bool get _canGenerate => _painPointsController.text.trim().isNotEmpty;

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(duration: AppDuration.normal, curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: AppDuration.normal, curve: Curves.easeInOut);
    }
  }

  void _jumpTo(int i) {
    _pageController.animateToPage(i, duration: AppDuration.normal, curve: Curves.easeInOut);
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
        guidedContext['target_customer'] = _targetCustomerController.text.trim();
      }
      if (_hypothesisController.text.trim().isNotEmpty) {
        guidedContext['hypothesis'] = _hypothesisController.text.trim();
      }
      if (_marketContextController.text.trim().isNotEmpty) {
        guidedContext['market_context'] = _marketContextController.text.trim();
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
          'variants_json': response.variants.map((v) => v.toJson()).toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                      IconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                      const Spacer(),
                      Text('THE INTERVIEW', style: AppText.monoMeta),
                      const Spacer(),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),

                // Subject line
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 14),
                  child: Text(
                    'Re: ${widget.productText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: fontDisplay,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: AppColors.graphite,
                    ),
                  ),
                ),

                // Chapter tabs
                _ChapterTabs(
                  count: _steps.length,
                  current: _currentPage,
                  onTap: _jumpTo,
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      final controller = _controllerForStep(index);
                      return _buildStepPage(step, controller, index);
                    },
                  ),
                ),

                // Footer
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
                  child: _currentPage == _steps.length - 1
                      ? _buildLastPageButtons()
                      : _buildNavButtons(),
                ),
              ],
            ),
          ),
          if (_isLoading) const LoadingOverlay(message: 'Crafting your personalized ideas...'),
        ],
      ),
    );
  }

  Widget _buildStepPage(_WizardStep step, TextEditingController controller, int index) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(step.eyebrow, style: AppText.monoMeta),
              const SizedBox(width: 8),
              if (step.required_)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    'REQUIRED',
                    style: AppText.monoMeta.copyWith(color: AppColors.accentInk, fontSize: 9),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(step.title, style: AppText.display2),
          const SizedBox(height: 8),
          Text(step.subtitle, style: AppText.lede),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: AppColors.canvas,
              border: Border.all(color: AppColors.hairline),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TextField(
              controller: controller,
              maxLines: 7,
              minLines: 5,
              style: AppText.body.copyWith(height: 1.55),
              cursorColor: AppColors.accentInk,
              decoration: InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                hintText: step.hint,
                hintMaxLines: 3,
                hintStyle: AppText.body.copyWith(
                  color: AppColors.mist, fontStyle: FontStyle.italic, height: 1.5,
                ),
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
          StudioButton(
            label: 'Back',
            icon: Icons.arrow_back_rounded,
            kind: BtnKind.ghost,
            onPressed: _prevPage,
          )
        else
          const SizedBox.shrink(),
        const Spacer(),
        StudioButton(
          label: 'Next',
          icon: Icons.arrow_forward_rounded,
          kind: BtnKind.primary,
          onPressed: _nextPage,
        ),
      ],
    );
  }

  Widget _buildLastPageButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: StudioButton(
            label: 'Generate ideas',
            icon: Icons.auto_awesome_rounded,
            kind: BtnKind.primary,
            onPressed: _canGenerate ? _generate : null,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            StudioButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              kind: BtnKind.ghost,
              onPressed: _prevPage,
            ),
            Text('2 credits', style: AppText.monoMeta),
          ],
        ),
      ],
    );
  }
}

class _ChapterTabs extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onTap;
  const _ChapterTabs({required this.count, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == current;
          return InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? AppColors.ink : AppColors.canvas,
                border: Border.all(color: active ? AppColors.ink : AppColors.hairline),
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                '${(i + 1).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontFamily: fontMono, fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: active ? AppColors.canvas : AppColors.graphite,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WizardStep {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String hint;
  final bool required_;

  const _WizardStep({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.hint,
    this.required_ = false,
  });
}
