import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../models/conversation.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/user_avatar.dart';
import '../requests/skill_requests_screen.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final me = context.select<AuthProvider, String>((a) => a.userId ?? '');
    final pending = context.select<SkillRequestProvider, int>((r) => r.pendingCount);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Nachrichten'),
        actions: [
          IconButton(
            tooltip: 'Anfragen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SkillRequestsScreen()),
            ),
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: kError,
              child: const Icon(Icons.inbox_outlined, color: kTextSecondary),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'create-group',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
        ),
        icon: const Icon(Icons.group_add_outlined),
        label: const Text(
          'Neue Gruppe',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => chat.loadConversations(silent: true),
        child: _body(context, chat, me),
      ),
    );
  }

  Widget _body(BuildContext context, ChatProvider chat, String me) {
    if (chat.loading && chat.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chat.conversations.isEmpty) {
      return ListView(
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.6,
            child: EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: chat.error != null ? 'Fehler beim Laden' : 'Noch keine Chats',
              message: chat.error ??
                  'Schreib jemandem über einen Skill, nimm eine Anfrage an '
                      'oder gründe eine Gruppe.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: chat.conversations.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 76),
      itemBuilder: (_, i) => _ConversationTile(
        conversation: chat.conversations[i],
        me: me,
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.me});

  final Conversation conversation;
  final String me;

  @override
  Widget build(BuildContext context) {
    final title = conversation.titleFor(me);
    final partner = conversation.partnerOf(me);
    final last = conversation.lastMessage;
    final at = conversation.lastMessageAt;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: conversation.isGroup
          ? const GroupAvatar(radius: 26)
          : UserAvatar(url: partner?.avatarUrl, name: title, radius: 26),
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: kTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        last ?? 'Noch keine Nachrichten',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: last == null ? kTextMuted : kTextSecondary,
          fontSize: 13,
          fontStyle: last == null ? FontStyle.italic : null,
        ),
      ),
      trailing: at == null
          ? null
          : Text(
              formatChatListTime(at),
              style: const TextStyle(color: kTextMuted, fontSize: 11),
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      ),
    );
  }
}
