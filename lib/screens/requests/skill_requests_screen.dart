import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/skill_request.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../chat/chat_screen.dart';

class SkillRequestsScreen extends StatelessWidget {
  const SkillRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kBgDark,
        appBar: AppBar(
          title: const Text('Anfragen'),
          bottom: const TabBar(
            labelColor: kNeonOrange,
            unselectedLabelColor: kTextMuted,
            indicatorColor: kNeonOrange,
            tabs: [
              Tab(text: 'Erhalten'),
              Tab(text: 'Gesendet'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ReceivedTab(),
            _SentTab(),
          ],
        ),
      ),
    );
  }
}

class _ReceivedTab extends StatelessWidget {
  const _ReceivedTab();

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<SkillRequestProvider>().received;
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        text: 'Keine Anfragen erhalten',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) => _ReceivedCard(request: requests[i]),
    );
  }
}

class _SentTab extends StatelessWidget {
  const _SentTab();

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<SkillRequestProvider>().sent;
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.send_outlined,
        text: 'Keine Anfragen gesendet',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (_, i) => _SentCard(request: requests[i]),
    );
  }
}

class _ReceivedCard extends StatefulWidget {
  final SkillRequest request;
  const _ReceivedCard({required this.request});

  @override
  State<_ReceivedCard> createState() => _ReceivedCardState();
}

class _ReceivedCardState extends State<_ReceivedCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    final profile = context.read<ProfileProvider>().profile;
    final (convId, err) =
        await context.read<SkillRequestProvider>().acceptRequest(
              request: widget.request,
              currentUserName: profile?.userName ?? 'Anonym',
              currentUserAvatar: profile?.avatarUrl,
              chatProvider: context.read<ChatProvider>(),
            );

    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $err')));
      return;
    }

    final conversations = context.read<ChatProvider>().conversations;
    final conv = conversations.firstWhere((c) => c.id == convId!);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    );
  }

  Future<void> _reject() async {
    setState(() => _loading = true);
    final err = await context
        .read<SkillRequestProvider>()
        .rejectRequest(widget.request.id);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $err')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final isPending = req.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? kNeonOrange.withOpacity(0.3)
              : kBorderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: kBgCardElevated,
                backgroundImage: req.requesterAvatar != null
                    ? NetworkImage(req.requesterAvatar!)
                    : null,
                child: req.requesterAvatar == null
                    ? Text(
                        (req.requesterName ?? '?')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: kNeonOrange,
                            fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req.requesterName ?? 'Anonym',
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                    if (req.skillTitle != null)
                      Text(
                        'Möchte: ${req.skillTitle}',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12),
                      ),
                  ],
                ),
              ),
              _StatusBadge(status: req.status),
            ],
          ),
          if (req.message != null && req.message!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kBgCardElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '"${req.message}"',
                style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kError,
                      side: BorderSide(
                          color: kError.withOpacity(0.5), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kError))
                        : const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Annehmen & Chatten'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  final SkillRequest request;
  const _SentCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final req = request;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kNeonOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: kNeonOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  req.skillTitle ?? 'Skill',
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
                Text(
                  _formatDate(req.createdAt),
                  style: const TextStyle(
                      color: kTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _StatusBadge(status: req.status),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day}.${local.month}.${local.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'accepted':
        color = kSuccess;
        label = 'Angenommen';
        break;
      case 'rejected':
        color = kError;
        label = 'Abgelehnt';
        break;
      default:
        color = kNeonOrange;
        label = 'Ausstehend';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: kTextMuted, size: 48),
          const SizedBox(height: 12),
          Text(text,
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
