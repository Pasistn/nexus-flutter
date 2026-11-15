import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../models/rating.dart';

class RatingsProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  static const maxCommentLength = 1000;
  static const _chunkSize = 100;

  final Map<String, RatingSummary> _cache = {};
  final Set<String> _queued = {};
  final Set<String> _inFlight = {};
  Timer? _batchTimer;

  RatingSummary? summaryFor(String userId) => _cache[userId];

  void ensureLoaded(String userId) {
    if (userId.isEmpty ||
        _cache.containsKey(userId) ||
        _inFlight.contains(userId)) {
      return;
    }
    _queued.add(userId);
    _batchTimer ??= Timer(const Duration(milliseconds: 40), _flush);
  }

  Future<void> refresh(String userId) async {
    _cache.remove(userId);
    await _fetch([userId]);
  }

  Future<void> _flush() async {
    _batchTimer = null;
    final ids = _queued.toList();
    _queued.clear();
    for (var i = 0; i < ids.length; i += _chunkSize) {
      final end = i + _chunkSize < ids.length ? i + _chunkSize : ids.length;
      await _fetch(ids.sublist(i, end));
    }
  }

  Future<void> _fetch(List<String> userIds) async {
    _inFlight.addAll(userIds);
    try {
      final rows = await _client
          .from(Tables.ratings)
          .select()
          .inFilter('rated_user_id', userIds)
          .order('created_at', ascending: false);

      final byUser = <String, List<Rating>>{};
      for (final r in rows.map(Rating.fromJson)) {
        byUser.putIfAbsent(r.ratedUserId, () => []).add(r);
      }
      for (final id in userIds) {
        _cache[id] = RatingSummary.of(byUser[id] ?? const []);
      }
    } catch (e) {
      friendlyError(e);
      for (final id in userIds) {
        _cache.putIfAbsent(id, () => RatingSummary.empty);
      }
    } finally {
      _inFlight.removeAll(userIds);
      notifyListeners();
    }
  }

  Future<String?> submit({
    required String ratedUserId,
    required int stars,
    String? comment,
    String? skillId,
  }) async {
    final me = _client.auth.currentUser?.id;
    if (me == null) return 'Bitte melde dich an.';
    if (me == ratedUserId) return 'Du kannst dich nicht selbst bewerten.';
    if (stars < 1 || stars > 5) return 'Bitte wähle 1 bis 5 Sterne.';
    if ((comment?.length ?? 0) > maxCommentLength) {
      return 'Kommentar ist zu lang (max. $maxCommentLength Zeichen).';
    }

    try {
      await _client.from(Tables.ratings).upsert(
        {
          'rater_id': me,
          'rated_user_id': ratedUserId,
          'skill_id': skillId,
          'rating': stars,
          'comment': comment,
        },
        onConflict: 'rater_id,rated_user_id',
      );
    } catch (e) {
      return friendlyError(e);
    }
    await refresh(ratedUserId);
    return null;
  }

  void clear() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _cache.clear();
    _queued.clear();
    _inFlight.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _batchTimer?.cancel();
    super.dispose();
  }
}
