import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/skill_request.dart';
import 'chat_provider.dart';

class SkillRequestProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<SkillRequest> _received = [];
  List<SkillRequest> _sent = [];
  bool _loading = false;
  String? _error;
  RealtimeChannel? _channel;
  String? _userId;

  List<SkillRequest> get received => _received;
  List<SkillRequest> get sent => _sent;
  int get pendingCount =>
      _received.where((r) => r.status == 'pending').length;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadRequests(String userId) async {
    _userId = userId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _client
          .from('skill_requests')
          .select()
          .or('requester_id.eq.$userId,skill_owner_id.eq.$userId')
          .order('created_at', ascending: false);

      final list = (data as List)
          .map((e) => SkillRequest.fromJson(e as Map<String, dynamic>))
          .toList();

      _received = list.where((r) => r.skillOwnerId == userId).toList();
      _sent = list.where((r) => r.requesterId == userId).toList();

      _channel ??= _client
          .channel('skill_requests_rt')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'skill_requests',
            callback: (_) {
              if (_userId != null) loadRequests(_userId!);
            },
          )
          .subscribe();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> createRequest({
    required String skillId,
    required String skillTitle,
    required String requesterId,
    required String? requesterName,
    required String? requesterAvatar,
    required String skillOwnerId,
    String? message,
  }) async {
    final alreadyPending = _sent.any(
      (r) => r.skillId == skillId && r.status == 'pending',
    );
    if (alreadyPending) return 'Du hast diesen Skill bereits angefragt';

    try {
      await _client.from('skill_requests').insert({
        'skill_id': skillId,
        'skill_title': skillTitle,
        'requester_id': requesterId,
        'requester_name': requesterName,
        'requester_avatar': requesterAvatar,
        'skill_owner_id': skillOwnerId,
        'status': 'pending',
        if (message != null && message.isNotEmpty) 'message': message,
      });
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<(String?, String?)> acceptRequest({
    required SkillRequest request,
    required String currentUserName,
    required String? currentUserAvatar,
    required ChatProvider chatProvider,
  }) async {
    try {
      await _client
          .from('skill_requests')
          .update({'status': 'accepted'})
          .eq('id', request.id);

      return chatProvider.createDirectChat(
        currentUserId: request.skillOwnerId,
        currentUserName: currentUserName,
        currentUserAvatar: currentUserAvatar,
        otherUserId: request.requesterId,
        otherUserName: request.requesterName ?? 'Anonym',
        otherUserAvatar: request.requesterAvatar,
        skillId: request.skillId,
      );
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<String?> rejectRequest(String requestId) async {
    try {
      await _client
          .from('skill_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
