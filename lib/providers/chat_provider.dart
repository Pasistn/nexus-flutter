import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../models/conversation.dart';
import '../models/message.dart';

typedef ChatResult = ({String? conversationId, String? error});

class ChatProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  static const maxMessageLength = 4000;
  static const _pageSize = 200;

  List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messages = {};
  bool _loading = false;
  String? _error;

  RealtimeChannel? _messageChannel;
  RealtimeChannel? _conversationChannel;
  Timer? _reloadTimer;

  List<Conversation> get conversations => _conversations;
  bool get loading => _loading;
  String? get error => _error;

  List<Message> messagesFor(String conversationId) =>
      _messages[conversationId] ?? const [];

  Conversation? byId(String id) {
    for (final c in _conversations) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> loadConversations({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final rows = await _client
          .from(Tables.conversations)
          .select('*, conversation_members(*)')
          .order('last_message_at', ascending: false, nullsFirst: false);
      _conversations = rows.map(Conversation.fromJson).toList();
      _error = null;
      _listen();
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _listen() {
    _messageChannel ??= _client
        .channel('rt-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: Tables.messages,
          callback: (payload) {
            try {
              _addMessage(Message.fromJson(payload.newRecord));
            } catch (_) {}
          },
        )
        .subscribe();

    _conversationChannel ??= _client
        .channel('rt-conversations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.conversations,
          callback: (_) => _scheduleReload(),
        )
        .subscribe();
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(
      const Duration(milliseconds: 500),
      () => loadConversations(silent: true),
    );
  }

  void _addMessage(Message msg) {
    final thread = _messages[msg.conversationId] ?? const <Message>[];
    if (!thread.any((m) => m.id == msg.id)) {
      _messages[msg.conversationId] = [...thread, msg];
    }

    final idx = _conversations.indexWhere((c) => c.id == msg.conversationId);
    if (idx == -1) {
      _scheduleReload();
    } else {
      _conversations = [..._conversations]
        ..[idx] = _conversations[idx].withLastMessage(msg.content, msg.createdAt)
        ..sort((a, b) => b.sortKey.compareTo(a.sortKey));
    }
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final rows = await _client
          .from(Tables.messages)
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(_pageSize);
      _messages[conversationId] =
          rows.map(Message.fromJson).toList().reversed.toList();
      notifyListeners();
    } catch (e) {
      friendlyError(e);
    }
  }

  Future<String?> sendMessage(String conversationId, String content) async {
    final text = content.trim();
    if (text.isEmpty) return null;
    if (text.length > maxMessageLength) {
      return 'Nachricht ist zu lang (max. $maxMessageLength Zeichen).';
    }

    try {
      final row = await _client
          .from(Tables.messages)
          .insert({
            'conversation_id': conversationId,
            'sender_id': _client.auth.currentUser?.id,
            'content': text,
          })
          .select()
          .single();
      _addMessage(Message.fromJson(row));
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<ChatResult> openDirectChat(String otherUserId, {String? skillId}) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return (conversationId: null, error: 'Nicht angemeldet.');

    for (final c in _conversations) {
      if (!c.isGroup && c.hasMember(me) && c.hasMember(otherUserId)) {
        return (conversationId: c.id, error: null);
      }
    }

    return _callAndReload('create_direct_chat', {
      'p_other_user_id': otherUserId,
      'p_skill_id': skillId,
    });
  }

  Future<ChatResult> createGroup(String name, List<String> memberIds) =>
      _callAndReload('create_group_chat', {
        'p_name': name.trim(),
        'p_member_ids': memberIds,
      });

  Future<ChatResult> _callAndReload(
    String fn,
    Map<String, dynamic> params,
  ) async {
    try {
      final id = await _client.rpc(fn, params: params) as String;
      await loadConversations(silent: true);
      return (conversationId: id, error: null);
    } catch (e) {
      return (conversationId: null, error: friendlyError(e));
    }
  }

  void clear() {
    _reloadTimer?.cancel();
    _unsubscribe();
    _conversations = [];
    _messages.clear();
    _error = null;
    _loading = false;
    notifyListeners();
  }

  void _unsubscribe() {
    for (final ch in [_messageChannel, _conversationChannel]) {
      if (ch != null) _client.removeChannel(ch);
    }
    _messageChannel = null;
    _conversationChannel = null;
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    _unsubscribe();
    super.dispose();
  }
}
