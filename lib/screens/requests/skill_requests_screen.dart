import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../models/skill_request.dart';
import '../../providers/chat_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/user_avatar.dart';
import '../chat/chat_screen.dart';

class SkillRequestsScreen extends StatelessWidget {
  const SkillRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillRequestProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Anfragen'),
          bottom: TabBar(
            labelColor: kPrimary,
            unselectedLabelColor: kTextMuted,
            indicatorColor: kPrimary,
            tabs: [
              Tab(text: 'Erhalten (${provider.received.length})'),
              Tab(text: 'Gesendet (${provider.sent.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(
              requests: provider.received,
              empty: const EmptyState(
                icon: Icons.inbox_outlined,
                title: 'Keine Anfragen erhalten',
                message: 'Sobald jemand einen deiner Skills anfragt, '
                    'taucht das hier auf.',
              ),
              itemBuilder: (r) => _ReceivedCard(request: r),
            ),
            _RequestList(
              requests: provider.sent,
              empty: const EmptyState(
                icon: Icons.send_outlined,
                title: 'Noch nichts angefragt',
              ),
              itemBuilder: (r) => _SentCard(request: r),
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    required this.empty,
    required this.itemBuilder,
  });

  final List<SkillRequest> requests;
  final Widget empty;
  final Widget Function(SkillRequest) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return empty;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => itemBuilder(requests[i]),
    );
  }
}

class _ReceivedCard extends StatefulWidget {
  const _ReceivedCard({required this.request});

  final SkillRequest request;

  @override
  State<_ReceivedCard> createState() => _ReceivedCardState();
}

class _ReceivedCardState extends State<_ReceivedCard> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final chat = context.read<ChatProvider>();
    final result =
        await context.read<SkillRequestProvider>().accept(widget.request, chat);
    if (!mounted) return;
    setState(() => _busy = false);

    final conv = result.conversationId == null
        ? null
        : chat.byId(result.conversationId!);
    if (conv == null) {
      showSnack(
        context,
        result.error ?? 'Chat konnte nicht geöffnet werden.',
        error: true,
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
    );
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    final err =
        await context.read<SkillRequestProvider>().reject(widget.request.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) showSnack(context, err, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.request;
    final message = req.message;

    return _Card(
      highlighted: req.isPending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                url: req.requesterAvatar,
                name: req.requesterName,
                radius: 22,
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
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'möchte: ${req.skillTitle ?? 'deinen Skill'}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _StatusBadge(req.status),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '„$message“',
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (req.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kError,
                      side: BorderSide(color: kError.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Ablehnen'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: _busy
                        ? const ButtonSpinner()
                        : const Text('Annehmen & chatten'),
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
  const _SentCard({required this.request});

  final SkillRequest request;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: kPrimary.withValues(alpha: 0.1),
            child: const Icon(Icons.bolt, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.skillTitle ?? 'Skill',
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  formatDate(request.createdAt),
                  style: const TextStyle(color: kTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          _StatusBadge(request.status),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? kPrimary.withValues(alpha: 0.3) : kBorder,
        ),
      ),
      child: child,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RequestStatus.accepted => (kSuccess, 'Angenommen'),
      RequestStatus.rejected => (kError, 'Abgelehnt'),
      RequestStatus.pending => (kPrimary, 'Offen'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
