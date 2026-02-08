import 'package:flutter/material.dart';

import '../models/session_summary.dart';
import '../services/api_client.dart';
import '../theme.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
          SnackBar(
            content: const Text('Session deleted'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Ideas')),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.warmWhite, Color(0xFFFFF9F0)],
              ),
            ),
          ),
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAmber,
                    strokeWidth: 3,
                    strokeCap: StrokeCap.round,
                  ),
                )
              : _sessions == null || _sessions!.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: AppColors.primaryAmber,
                      onRefresh: _loadSessions,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.base,
                          AppSpacing.sm,
                          AppSpacing.base,
                          AppSpacing.xl,
                        ),
                        itemCount: _sessions!.length,
                        itemBuilder: (context, index) {
                          final session = _sessions![index];
                          return _SessionTile(
                            session: session,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SessionDetailScreen(
                                      sessionId: session.id),
                                ),
                              );
                              _loadSessions();
                            },
                            onDelete: () => _deleteSession(session),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryAmber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 36,
                color: AppColors.primaryAmber,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No ideas yet!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkCharcoal,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Every great product starts with an idea.\nGo create one!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.mutedGray,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionSummary session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SessionTile({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.lightWarmGray.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.base),
            child: Row(
              children: [
                // Status icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAmber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    _iconForStatus(session.status),
                    color: AppColors.primaryAmber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.displayTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkCharcoal,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusChip(status: session.statusLabel),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            _formatDate(session.updatedAt),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.mutedGray),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 20, color: AppColors.mutedGray),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForStatus(String status) {
    switch (status) {
      case 'exported':
        return Icons.description_rounded;
      case 'patents_searched':
        return Icons.search_rounded;
      case 'spec_generated':
        return Icons.analytics_rounded;
      case 'ideas_generated':
        return Icons.lightbulb_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

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
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: AppColors.primaryAmber,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
