import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/studio_widgets.dart';

// ─────────────────────────────────────────────────────────────────────
// Market Trends — The Dispatch
//
// A weekly market-intelligence broadsheet. Masthead with issue line,
// serif display title, lede. Trends as numbered editorial entries —
// big fraction rank, category metadata row, headline, body, an inset
// accent-soft "Opportunity" pull-quote, and a growth signal footer.
// ─────────────────────────────────────────────────────────────────────

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
    const months = ['JAN','FEB','MAR','APR','MAY','JUN','JUL','AUG','SEP','OCT','NOV','DEC'];
    return 'ISSUE · ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('THE DISPATCH', style: AppText.monoMeta),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk, strokeWidth: 2))
                  : _error != null
                      ? _errorView()
                      : RefreshIndicator(
                          color: AppColors.accentInk,
                          onRefresh: () async {
                            setState(() => _loading = true);
                            await _loadTrends();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 48),
                            itemCount: _trends.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _masthead();
                              return _TrendEntry(trend: _trends[index - 1]);
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
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 24, height: 2, color: AppColors.accentInk),
              const SizedBox(width: 10),
              Text(_issueLine(), style: AppText.monoMeta),
            ],
          ),
          const SizedBox(height: 14),
          Text('Market ', style: AppText.display1),
          Text(
            'Weather',
            style: AppText.display1.copyWith(
              fontStyle: FontStyle.italic, color: AppColors.accentInk,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Ten categories worth your attention this cycle — where consumer demand is bending, and what opportunity sits inside the bend.',
            style: AppText.lede,
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: AppColors.hairline),
        ],
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
            Text('Could not load trends', style: AppText.display3),
            const SizedBox(height: 10),
            StudioButton(
              label: 'Try again',
              icon: Icons.refresh_rounded,
              kind: BtnKind.primary,
              onPressed: () {
                setState(() { _loading = true; _error = null; });
                _loadTrends();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendEntry extends StatelessWidget {
  final Map<String, dynamic> trend;
  const _TrendEntry({required this.trend});

  @override
  Widget build(BuildContext context) {
    final rank = trend['rank'] ?? 0;
    final title = trend['title'] ?? '';
    final category = trend['category'] ?? '';
    final description = trend['description'] ?? '';
    final opportunity = trend['opportunity'] ?? '';
    final growthSignal = trend['growth_signal'] ?? '';

    final rankStr = rank.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Big rank
              Text(
                rankStr,
                style: TextStyle(
                  fontFamily: fontDisplay,
                  fontSize: 56,
                  fontWeight: FontWeight.w300,
                  color: AppColors.accentInk,
                  height: 0.9,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(category.toString().toUpperCase(), style: AppText.monoMeta),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(title, style: AppText.display3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (description.toString().isNotEmpty)
            Text(description, style: AppText.body.copyWith(height: 1.6)),
          if (opportunity.toString().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border(left: BorderSide(color: AppColors.accentInk, width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THE OPENING', style: AppText.monoMeta.copyWith(color: AppColors.accentInk)),
                  const SizedBox(height: 6),
                  Text(
                    opportunity,
                    style: AppText.body.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.accentInk,
                    ),
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
                Icon(Icons.trending_up_rounded, size: 14, color: AppColors.accentInk),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(growthSignal, style: AppText.caption),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.hairline),
        ],
      ),
    );
  }
}
