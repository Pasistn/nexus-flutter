import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>().profile;
    if (!auth.isAuthenticated) return;

    setState(() => _sending = true);
    _inputCtrl.clear();

    final err = await context.read<ChatProvider>().sendMessage(
          conversationId: widget.conversation.id,
          content: text,
          senderId: auth.currentUser!.id,
          senderName: profile?.userName ?? 'Anonym',
        );

    if (!mounted) return;
    setState(() => _sending = false);
    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id ?? '';
    final chat = context.watch<ChatProvider>();
    final messages = chat.messagesFor(widget.conversation.id);
    final title = widget.conversation.displayName(currentUserId);

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(widget.conversation, currentUserId),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.conversation.type == 'group')
                    Text(
                      '${widget.conversation.members.length} Mitglieder',
                      style: const TextStyle(
                          color: kTextSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.conversation.type == 'group')
            IconButton(
              icon: const Icon(Icons.group, color: kTextSecondary),
              onPressed: () => _showMembers(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: kTextMuted, size: 48),
                        SizedBox(height: 12),
                        Text('Noch keine Nachrichten',
                            style:
                                TextStyle(color: kTextSecondary, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Schreib die erste Nachricht!',
                            style:
                                TextStyle(color: kTextMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == currentUserId;
                      final showName = !isMe &&
                          widget.conversation.type == 'group' &&
                          (i == 0 ||
                              messages[i - 1].senderId != msg.senderId);
                      return _buildBubble(
                          msg, isMe, showName, i, messages);
                    },
                  ),
          ),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildAvatar(Conversation conv, String currentUserId) {
    final avatar = conv.otherAvatar(currentUserId);
    final initial = conv.displayName(currentUserId).substring(0, 1).toUpperCase();
    if (conv.type == 'group') {
      return CircleAvatar(
        radius: 18,
        backgroundColor: kNeonOrange.withOpacity(0.15),
        child: const Icon(Icons.group, color: kNeonOrange, size: 18),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: kBgCardElevated,
      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
      child: avatar == null
          ? Text(initial,
              style: const TextStyle(
                  color: kNeonOrange,
                  fontWeight: FontWeight.w700,
                  fontSize: 14))
          : null,
    );
  }

  Widget _buildBubble(Message msg, bool isMe, bool showSenderName, int i,
      List<Message> messages) {
    final showTime = i == messages.length - 1 ||
        messages[i + 1].createdAt.difference(msg.createdAt).inMinutes > 5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showSenderName)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                msg.senderName,
                style: const TextStyle(
                    color: kNeonOrange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                const SizedBox(width: 4),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? kNeonOrange : kBgCard,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: kBorderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : kTextPrimary,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
          if (showTime)
            Padding(
              padding: EdgeInsets.only(
                  top: 4,
                  left: isMe ? 0 : 12,
                  right: isMe ? 12 : 0,
                  bottom: 4),
              child: Text(
                _formatTime(msg.createdAt),
                style:
                    const TextStyle(color: kTextMuted, fontSize: 10.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: kBgDark,
        border: Border(top: BorderSide(color: kBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText: 'Nachricht schreiben...',
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              style: const TextStyle(color: kTextPrimary, fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kNeonOrange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showMembers() {
    final members = widget.conversation.members;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: kBorderColor,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${members.length} Mitglieder',
              style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...members.map((m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: kBgCardElevated,
                    backgroundImage:
                        m.avatarUrl != null ? NetworkImage(m.avatarUrl!) : null,
                    child: m.avatarUrl == null
                        ? Text(
                            (m.userName ?? '?')
                                .substring(0, 1)
                                .toUpperCase(),
                            style: const TextStyle(
                                color: kNeonOrange,
                                fontWeight: FontWeight.w700))
                        : null,
                  ),
                  title: Text(m.userName ?? 'Anonym',
                      style: const TextStyle(color: kTextPrimary)),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final local = dt.toLocal();
    final diff = now.difference(local);
    if (diff.inDays == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return 'Gestern';
    return '${local.day}.${local.month}.${local.year}';
  }
}
