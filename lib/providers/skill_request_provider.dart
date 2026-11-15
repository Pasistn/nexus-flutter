import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../models/skill_request.dart';
import 'chat_provider.dart';

class SkillRequestProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  static const maxMessageLength = 1000;

  List<SkillRequest> _received = [];
  List<SkillRequest> _sent = [];
  bool _loading = false;
  String? _error;
  String? _userId;
  RealtimeChannel? _channel;
  Timer? _reloadTimer;

  List<SkillRequest> get received => _received;
  List<SkillRequest> get sent => _sent;
  int get pendingCount => _received.where((r) => r.isPending).length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String userId, {bool silent = false}) async {
    _userId = userId;
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final rows = await _client
          .from(Tables.skillRequests)
          .select()
          .order('created_at', ascending: false);
      final all = rows.map(SkillRequest.fromJson).toList();
      _received = all.where((r) => r.skillOwnerId == userId).toList();
      _sent = all.where((r) => r.requesterId == userId).toList();
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
    _channel ??= _client
        .channel('rt-skill-requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.skillRequests,
          callback: (_) {
            _reloadTimer?.cancel();
            _reloadTimer = Timer(const Duration(milliseconds: 500), () {
              final id = _userId;
              if (id != null) load(id, silent: true);
            });
          },
        )
        .subscribe();
  }

  bool hasPendingRequestFor(String skillId) =>
      _sent.any((r) => r.skillId == skillId && r.isPending);

  Future<String?> send(String skillId, {String? message}) async {
    if (hasPendingRequestFor(skillId)) {
      return 'Du hast diesen Skill bereits angefragt.';
    }
    if ((message?.length ?? 0) > maxMessageLength) {
      return 'Nachricht ist zu lang (max. $maxMessageLength Zeichen).';
    }

    try {
      await _client.from(Tables.skillRequests).insert({
        'skill_id': skillId,
        'requester_id': _client.auth.currentUser?.id,
        if (message != null) 'message': message,
      });
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<ChatResult> accept(SkillRequest request, ChatProvider chat) async {
    try {
      final id = await _client.rpc(
        'accept_skill_request',
        params: {'p_request_id': request.id},
      ) as String;
      await chat.loadConversations(silent: true);
      return (conversationId: id, error: null);
    } catch (e) {
      return (conversationId: null, error: friendlyError(e));
    }
  }

  Future<String?> reject(String requestId) async {
    try {
      await _client
          .from(Tables.skillRequests)
          .update({'status': RequestStatus.rejected.name})
          .eq('id', requestId)
          .eq('status', RequestStatus.pending.name);
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  void clear() {
    _reloadTimer?.cancel();
    if (_channel != null) _client.removeChannel(_channel!);
    _channel = null;
    _userId = null;
    _received = [];
    _sent = [];
    _error = null;
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}
