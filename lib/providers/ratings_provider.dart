import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rating.dart';

class RatingsProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  final Map<String, RatingSummary> _cache = {};
  final Set<String> _loadingIds = {};

  RatingSummary? getSummary(String userId) => _cache[userId];
  bool isLoading(String userId) => _loadingIds.contains(userId);

  Future<void> loadForUser(String userId) async {
    if (_loadingIds.contains(userId)) return;
    _loadingIds.add(userId);
    notifyListeners();

    try {
      final data = await _client
          .from('ratings')
          .select()
          .eq('rated_user_id', userId)
          .order('created_at', ascending: false);

      final ratings = (data as List).map((e) => Rating.fromJson(e)).toList();
      final avg = ratings.isEmpty
          ? 0.0
          : ratings.map((r) => r.rating).reduce((a, b) => a + b) /
              ratings.length;
      _cache[userId] =
          RatingSummary(avg: avg, count: ratings.length, reviews: ratings);
    } catch (_) {
      _cache[userId] = const RatingSummary(avg: 0, count: 0, reviews: []);
    } finally {
      _loadingIds.remove(userId);
      notifyListeners();
    }
  }

  Future<String?> submitRating({
    required String ratedUserId,
    required int rating,
    required String? raterName,
    String? comment,
    String? skillId,
  }) async {
    try {
      final raterId = _client.auth.currentUser!.id;
      await _client.from('ratings').upsert(
        {
          'rater_id': raterId,
          'rater_name': raterName,
          'rated_user_id': ratedUserId,
          'skill_id': skillId,
          'rating': rating,
          'comment': comment,
        },
        onConflict: 'rater_id,rated_user_id',
      );
      _cache.remove(ratedUserId);
      await loadForUser(ratedUserId);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
