import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/whiskers_widgets.dart';

class MarketTrendsScreen extends StatefulWidget {
  const MarketTrendsScreen({super.key});

  @override
  State<MarketTrendsScreen> createState() => _MarketTrendsScreenState();
}

class _MarketTrendsScreenState extends State<MarketTrendsScreen> {
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTrends();
  }

  Future<void> _loadTrends() async {
    try {
      final trends = await ApiClient.instance.getMarketTrends();
      if (!mounted) return;
      setState(() {
        _trends = trends;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _issueLine() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context)),
                  const SizedBox(width: 4),
                  IconBtn(
                    icon: Icons.home_rounded,
                    onPressed: () => Navigator.of(context)
                        .popUntil((r) => r.isFirst),
                  ),
                  const Spacer(),
                  Text('Market Weather', style: AppText.sectionTitle),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.lav, strokeWidth: 2))
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          color: AppColors.lav,
                          onRefresh: () async {
                            setState(
                                () => _loading = true);
                            await _loadTrends();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 48),
                            itemCount: _trends.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _masthead();
                              return _TrendCard(
                                  trend: _trends[index - 1],
                                  index: index - 1);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _masthead() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: WCard(
        gradient: const LinearGradient(
          colors: [Color(0xFFEDE9FE), AppColors.lavLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Pill(_issueLine(),
                      bg: AppColors.lav, fg: Colors.white),
                  const SizedBox(height: 10),
                  Text('Market\nWeather',
                      style: AppText.display1
                          .copyWith(color: AppColors.ink, height: 1.1)),
                  const SizedBox(height: 8),
                  Text(
                    'Ten categories worth your attention this cycle — where demand is bending.',
                    style: AppText.caption
                        .copyWith(color: AppColors.lavDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Mascot(pose: MascotPose.detective, size: 72),
          ],
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot(pose: MascotPose.detective, size: 80),
            const SizedBox(height: 16),
            Text('Could not load trends', style: AppText.display3),
            const SizedBox(height: 16),
            PrimaryBtn(
              label: 'Try again',
              leading: Icons.refresh_rounded,
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadTrends();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Tile background colors cycling through Whiskers palette
const _tileBgs = [
  AppColors.lavLight,
  AppColors.sunBg,
  AppColors.mintBg,
  AppColors.peachBg,
  AppColors.pinkBg,
];

const _tileEmojis = ['📈', '🌿', '⚡', '🎯', '💡', '🔥', '🚀', '🔮', '🌊', '✨'];

class _TrendCard extends StatelessWidget {
  final Map<String, dynamic> trend;
  final int index;
  const _TrendCard({required this.trend, required this.index});

  @override
  Widget build(BuildContext context) {
    final rank = trend['rank'] ?? (index + 1);
    final title = trend['title'] ?? '';
    final category = trend['category'] ?? '';
    final description = trend['description'] ?? '';
    final opportunity = trend['opportunity'] ?? '';
    final growthSignal = trend['growth_signal'] ?? '';

    final tileBg = _tileBgs[index % _tileBgs.length];
    final emoji = _tileEmojis[index % _tileEmojis.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: tileBg,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(emoji,
                        style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            rank.toString().padLeft(2, '0'),
                            style: AppText.bodyBold.copyWith(
                                color: AppColors.lav, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          if (category.toString().isNotEmpty)
                            Pill(category.toString(),
                                bg: AppColors.lavLight,
                                fg: AppColors.lavDark),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(title, style: AppText.display3),
                    ],
                  ),
                ),
              ],
            ),

            if (description.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(description,
                  style: AppText.body
                      .copyWith(height: 1.6, color: AppColors.ink)),
            ],

            if (opportunity.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              WCard(
                color: AppColors.lavLight,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('The Opening',
                        style: AppText.tiny.copyWith(
                            color: AppColors.lavDark,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(
                      opportunity,
                      style: AppText.body.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.lavDark,
                          height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            if (growthSignal.toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 14, color: AppColors.lav),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(growthSignal,
                        style: AppText.caption),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
