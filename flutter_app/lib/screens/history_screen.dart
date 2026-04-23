import 'package:flutter/material.dart';

import '../models/session_summary.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/whiskers_widgets.dart';
import 'session_detail_screen.dart';

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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  IconBtn(
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Your Sessions', style: AppText.sectionTitle),
                  const Spacer(),
                  const Mascot(pose: MascotPose.cheese, size: 36),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Working file', style: AppText.display2),
                  const SizedBox(height: 6),
                  Text(
                    'Every session, kept. Pick up a draft or revisit something you shelved.',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.lav, strokeWidth: 2))
                  : _sessions == null || _sessions!.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          color: AppColors.lav,
                          onRefresh: _loadSessions,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                20, 0, 20, 32),
                            itemCount: _sessions!.length,
                            itemBuilder: (context, index) {
                              final s = _sessions![index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _SessionCard(
                                  session: s,
                                  index: index,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SessionDetailScreen(
                                            sessionId: s.id),
                                      ),
                                    );
                                    _loadSessions();
                                  },
                                  onDelete: () => _deleteSession(s),
                                ),
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
            const Mascot(pose: MascotPose.ideabox, size: 100),
            const SizedBox(height: 16),
            Text('A blank page.',
                style: AppText.display2.copyWith(color: AppColors.ink)),
            const SizedBox(height: 8),
            Text(
              'Nothing in the ledger yet.\nStart a session — it ends up here.',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}

const _sessionTileBgs = [
  AppColors.lavLight,
  AppColors.sunBg,
  AppColors.mintBg,
  AppColors.peachBg,
  AppColors.pinkBg,
];

const _sessionEmojis = ['💡', '🔥', '🚀', '⚡', '🎯'];

class _SessionCard extends StatelessWidget {
  final SessionSummary session;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionCard({
    required this.session,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tileBg = _sessionTileBgs[index % _sessionTileBgs.length];
    final emoji = _sessionEmojis[index % _sessionEmojis.length];

    return WCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Center(
              child: Text(emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyBold,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Pill(
                      session.statusLabel,
                      bg: AppColors.lavLight,
                      fg: AppColors.lavDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(session.updatedAt),
                      style: AppText.tiny,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 16, color: AppColors.inkSoft),
            onPressed: onDelete,
            tooltip: 'Delete',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
