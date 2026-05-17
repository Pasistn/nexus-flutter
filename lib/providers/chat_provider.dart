import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/conversation.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<Conversation> _conversations = [];
  final Map<String, List<Message>> _messages = {};
  bool _loading = false;
  String? _error;
  RealtimeChannel? _messageChannel;
  RealtimeChannel? _conversationChannel;

  List<Conversation> get conversations => _conversations;
  bool get loading => _loading;
  String? get error => _error;

  List<Message> messagesFor(String conversationId) =>
      _messages[conversationId] ?? [];

  Future<void> loadConversations() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _client
          .from('conversations')
          .select('*, conversation_members(*)')
          .order('last_message_at', ascending: false, nullsFirst: false);

      _conversations = (data as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();

      _subscribeToRealtime();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _subscribeToRealtime() {
    _messageChannel ??= _client
        .channel('chat_messages_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = Message.fromJson(payload.newRecord);
            _onNewMessage(msg);
          },
        )
        .subscribe();

    _conversationChannel ??= _client
        .channel('chat_conversations_rt')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => loadConversations(),
        )
        .subscribe();
  }

  void _onNewMessage(Message msg) {
    final list = List<Message>.from(_messages[msg.conversationId] ?? []);
    if (!list.any((m) => m.id == msg.id)) {
      list.add(msg);
      _messages[msg.conversationId] = list;
    }

    final idx =
        _conversations.indexWhere((c) => c.id == msg.conversationId);
    if (idx != -1) {
      final updated = _conversations[idx].copyWith(
        lastMessage: msg.content,
        lastMessageAt: msg.createdAt,
      );
      _conversations = List.from(_conversations)..[idx] = updated;
      _conversations.sort((a, b) =>
          (b.lastMessageAt ?? b.createdAt)
              .compareTo(a.lastMessageAt ?? a.createdAt));
    }
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final data = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      _messages[conversationId] = (data as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<String?> sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
    required String senderName,
  }) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': senderId,
        'sender_name': senderName,
        'content': content,
      });
      await _client.from('conversations').update({
        'last_message': content,
        'last_message_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', conversationId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<(String?, String?)> createGroupChat({
    required String name,
    required String currentUserId,
    required String currentUserName,
    required String? currentUserAvatar,
    required List<Map<String, dynamic>> members,
  }) async {
    try {
      final convData = await _client
          .from('conversations')
          .insert({
            'name': name,
            'type': 'group',
            'created_by': currentUserId,
          })
          .select()
          .single();

      final conversationId = convData['id'] as String;

      final allMembers = [
        {
          'conversation_id': conversationId,
          'user_id': currentUserId,
          'user_name': currentUserName,
          'avatar_url': currentUserAvatar,
        },
        ...members.map((m) => {
              'conversation_id': conversationId,
              'user_id': m['userId'],
              'user_name': m['userName'],
              'avatar_url': m['avatarUrl'],
            }),
      ];

      await _client.from('conversation_members').insert(allMembers);
      await loadConversations();
      return (conversationId, null);
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<(String?, String?)> createDirectChat({
    required String currentUserId,
    required String currentUserName,
    required String? currentUserAvatar,
    required String otherUserId,
    required String otherUserName,
    required String? otherUserAvatar,
    String? skillId,
  }) async {
    // Return existing direct chat if already present
    final existing = _conversations.where((c) =>
        c.type == 'direct' &&
        c.members.any((m) => m.userId == currentUserId) &&
        c.members.any((m) => m.userId == otherUserId));
    if (existing.isNotEmpty) {
      return (existing.first.id, null);
    }

    try {
      final convData = await _client
          .from('conversations')
          .insert({
            'type': 'direct',
            'created_by': currentUserId,
            if (skillId != null) 'skill_id': skillId,
          })
          .select()
          .single();

      final conversationId = convData['id'] as String;

      await _client.from('conversation_members').insert([
        {
          'conversation_id': conversationId,
          'user_id': currentUserId,
          'user_name': currentUserName,
          'avatar_url': currentUserAvatar,
        },
        {
          'conversation_id': conversationId,
          'user_id': otherUserId,
          'user_name': otherUserName,
          'avatar_url': otherUserAvatar,
        },
      ]);

      await loadConversations();
      return (conversationId, null);
    } catch (e) {
      return (null, e.toString());
    }
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    _conversationChannel?.unsubscribe();
    super.dispose();
  }
}
