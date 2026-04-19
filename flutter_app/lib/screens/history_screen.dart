import 'package:flutter/material.dart';

import '../models/session_summary.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/studio_widgets.dart';
import 'session_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────
// History — The Ledger
//
// A bound ledger of prior sessions. Each row is a file line with
// mono file-number, serif title, status chip, and a timestamp in
// small caps. Empty state is a hand-lettered cue, not a card.
// ─────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionSummary>? _sessions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await ApiClient.instance.listSessions();
      if (mounted) setState(() => _sessions = sessions);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSession(SessionSummary session) async {
    try {
      await ApiClient.instance.deleteSession(session.id);
      if (mounted) {
        setState(() => _sessions?.remove(session));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session deleted.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
                  Text('THE LEDGER', style: AppText.monoMeta),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Masthead
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your ', style: AppText.display1),
                  Text(
                    'working file',
                    style: AppText.display1.copyWith(
                      fontStyle: FontStyle.italic, color: AppColors.accentInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every session, kept. Pick up a draft or revisit something you shelved.',
                    style: AppText.lede,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.accentInk, strokeWidth: 2))
                  : _sessions == null || _sessions!.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.accentInk,
                          onRefresh: _loadSessions,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(22, 0, 22, 32),
                            itemCount: _sessions!.length,
                            separatorBuilder: (_, __) => Container(height: 1, color: AppColors.hairline),
                            itemBuilder: (context, index) {
                              final s = _sessions![index];
                              return _LedgerRow(
                                session: s,
                                index: index,
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SessionDetailScreen(sessionId: s.id),
                                    ),
                                  );
                                  _loadSessions();
                                },
                                onDelete: () => _deleteSession(s),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A blank ',
              style: AppText.display2,
            ),
            Text(
              'page.',
              style: AppText.display2.copyWith(
                fontStyle: FontStyle.italic, color: AppColors.accentInk,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nothing in the ledger yet.\nStart a session — it ends up here.',
              textAlign: TextAlign.center,
              style: AppText.lede,
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final SessionSummary session;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _LedgerRow({
    required this.session,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  String _fileNum() {
    var h = 0;
    for (final c in session.id.codeUnits) {
      h = (h * 31 + c) & 0xffff;
    }
    return 'F-${2000 + (h % 7999)}';
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
      if (diff.inHours < 24) return '${diff.inHours}H AGO';
      if (diff.inDays < 7) return '${diff.inDays}D AGO';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 62,
              child: Text(_fileNum(), style: AppText.monoMeta),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display3.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          session.statusLabel.toUpperCase(),
                          style: AppText.monoMeta.copyWith(color: AppColors.accentInk, fontSize: 9),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_formatDate(session.updatedAt), style: AppText.monoMeta),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.mist),
              onPressed: onDelete,
              tooltip: 'Delete',
              splashRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}
