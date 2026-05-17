import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../requests/skill_requests_screen.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id ?? '';
    final pendingCount =
        context.watch<SkillRequestProvider>().pendingCount;

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: kNeonOrange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_rounded,
                  color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('Nachrichten'),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.inbox_outlined, color: kTextSecondary),
                tooltip: 'Anfragen',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const SkillRequestsScreen()),
                ),
              ),
              if (pendingCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: kError,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: chat.loading
          ? const Center(
              child: CircularProgressIndicator(color: kNeonOrange))
          : chat.conversations.isEmpty
              ? _buildEmpty()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: chat.conversations.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (_, i) {
                    final conv = chat.conversations[i];
                    return _ConvTile(
                        conv: conv, currentUserId: currentUserId);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        backgroundColor: kNeonOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.group_add),
        label: const Text('Gruppe erstellen',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kNeonOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: kNeonOrange, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Noch keine Chats',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            const Text(
              'Nimm eine Skill-Anfrage an oder erstelle eine Gruppe, um loszulegen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final String currentUserId;

  const _ConvTile({required this.conv, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final title = conv.displayName(currentUserId);
    final avatar = conv.otherAvatar(currentUserId);
    final lastMsg = conv.lastMessage;
    final time = conv.lastMessageAt;
    final isGroup = conv.type == 'group';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor:
            isGroup ? kNeonOrange.withOpacity(0.12) : kBgCardElevated,
        backgroundImage:
            (!isGroup && avatar != null) ? NetworkImage(avatar) : null,
        child: isGroup
            ? const Icon(Icons.group, color: kNeonOrange, size: 26)
            : (avatar == null
                ? Text(
                    title.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: kNeonOrange,
                        fontWeight: FontWeight.w700,
                        fontSize: 18),
                  )
                : null),
      ),
      title: Text(
        title,
        style: const TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: lastMsg != null
          ? Text(
              lastMsg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: kTextSecondary, fontSize: 13),
            )
          : const Text(
              'Noch keine Nachrichten',
              style: TextStyle(
                  color: kTextMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic),
            ),
      trailing: time != null
          ? Text(_formatTime(time),
              style: const TextStyle(color: kTextMuted, fontSize: 11))
          : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inMinutes < 1) return 'Jetzt';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Gestern';
    return '${local.day}.${local.month}.';
  }
}
