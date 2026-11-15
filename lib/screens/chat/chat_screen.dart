import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/bottom_sheet.dart';
import '../../widgets/feedback.dart';
import '../../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  bool _sending = false;

  Conversation get _conv => widget.conversation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ChatProvider>().loadMessages(_conv.id),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _input.clear();

    final err = await context.read<ChatProvider>().sendMessage(_conv.id, text);
    if (!mounted) return;

    setState(() => _sending = false);
    if (err != null) {
      if (_input.text.isEmpty) _input.text = text;
      showSnack(context, err, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select<AuthProvider, String>((a) => a.userId ?? '');
    final messages = context.watch<ChatProvider>().messagesFor(_conv.id);
    final partner = _conv.partnerOf(me);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            _conv.isGroup
                ? const GroupAvatar(radius: 18)
                : UserAvatar(
                    url: partner?.avatarUrl,
                    name: partner?.userName,
                    radius: 18,
                  ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _conv.titleFor(me),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_conv.isGroup)
                    Text(
                      '${_conv.members.length} Mitglieder',
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_conv.isGroup)
            IconButton(
              tooltip: 'Mitglieder',
              icon: const Icon(Icons.people_outline, color: kTextSecondary),
              onPressed: _showMembers,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? const EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Noch keine Nachrichten',
                    message: 'Schreib die erste Nachricht!',
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final index = messages.length - 1 - i;
                      return _bubbleAt(messages, index, me);
                    },
                  ),
          ),
          _Composer(controller: _input, sending: _sending, onSend: _send),
        ],
      ),
    );
  }

  Widget _bubbleAt(List<Message> messages, int i, String me) {
    final msg = messages[i];
    final mine = msg.senderId == me;
    final prev = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;

    return _Bubble(
      message: msg,
      mine: mine,
      showName: _conv.isGroup && !mine && prev?.senderId != msg.senderId,
      showTime: next == null ||
          next.senderId != msg.senderId ||
          next.createdAt.difference(msg.createdAt).inMinutes > 5,
    );
  }

  void _showMembers() {
    showNexusSheet<void>(
      context,
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetTitle('${_conv.members.length} Mitglieder'),
          const SizedBox(height: 8),
          for (final m in _conv.members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(url: m.avatarUrl, name: m.userName),
              title: Text(m.userName ?? 'Anonym'),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.showName,
    required this.showTime,
  });

  final Message message;
  final bool mine;
  final bool showName;
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const tail = Radius.circular(4);
    final maxWidth = MediaQuery.sizeOf(context).width * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: showTime ? 8 : 2),
      child: Column(
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2, top: 6),
              child: Text(
                message.senderName,
                style: const TextStyle(
                  color: kPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? kPrimary : kSurface,
              borderRadius: BorderRadius.only(
                topLeft: r,
                topRight: r,
                bottomLeft: mine ? r : tail,
                bottomRight: mine ? tail : r,
              ),
              border: mine ? null : Border.all(color: kBorder),
            ),
            child: SelectableText(
              message.content,
              style: TextStyle(
                color: mine ? Colors.white : kTextPrimary,
                fontSize: 14.5,
                height: 1.4,
              ),
            ),
          ),
          if (showTime)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Text(
                formatMessageTime(message.createdAt),
                style: const TextStyle(color: kTextMuted, fontSize: 10.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: const BoxDecoration(
        color: kBackground,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: ChatProvider.maxMessageLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Nachricht schreiben …',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            style: IconButton.styleFrom(
              backgroundColor: kPrimary,
              fixedSize: const Size(46, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: sending
                ? const ButtonSpinner()
                : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
