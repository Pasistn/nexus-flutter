import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../core/utils/geo_utils.dart';
import '../models/skill.dart';

class SkillsProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<Skill> _allSkills = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  double _radiusKm = 500;
  String? _selectedCategoryId;
  RealtimeChannel? _channel;

  List<Skill> get allSkills => _allSkills;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  double get radiusKm => _radiusKm;
  String? get selectedCategoryId => _selectedCategoryId;

  List<Skill> filteredSkills({double? userLat, double? userLng}) {
    var result = _allSkills;

    if (_selectedCategoryId != null) {
      result = result.where((s) => s.categoryId == _selectedCategoryId).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      result = result
          .where((s) =>
              s.skillTitle.toLowerCase().contains(q) ||
              s.description.toLowerCase().contains(q) ||
              (s.userName?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    if (userLat != null && userLng != null) {
      result = result.where((s) {
        final dist = getDistance(userLat, userLng, s.lat, s.lng);
        return dist <= _radiusKm;
      }).toList();
    }

    return result;
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setRadius(double r) {
    _radiusKm = r;
    notifyListeners();
  }

  void setCategory(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  Future<void> loadSkills() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      List<dynamic> data;
      try {
        data = await _client
            .from(SupabaseConstants.skillsTable)
            .select('*, categories(id, name, icon)')
            .not('lat', 'is', null)
            .not('lng', 'is', null)
            .order('created_at', ascending: false);
      } catch (_) {
        // categories table not yet created → fall back to simple select
        data = await _client
            .from(SupabaseConstants.skillsTable)
            .select()
            .not('lat', 'is', null)
            .not('lng', 'is', null)
            .order('created_at', ascending: false);
      }

      final userIds = (data as List)
          .map((e) => e['user_id'])
          .where((id) => id != null)
          .toSet()
          .toList();

      Map<String, String?> avatarMap = {};
      if (userIds.isNotEmpty) {
        final profiles = await _client
            .from(SupabaseConstants.profilesTable)
            .select('id, avatar_url')
            .inFilter('id', userIds);
        avatarMap = {
          for (final p in profiles as List)
            p['id'] as String: _resolveAvatarUrl(p['avatar_url'] as String?)
        };
      }

      _allSkills = data.map((e) {
        final row = Map<String, dynamic>.from(e);
        row['avatar_url'] = avatarMap[row['user_id']];
        return Skill.fromJson(row);
      }).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }

    _channel ??= _client
        .channel('skills_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: SupabaseConstants.skillsTable,
          callback: (_) => loadSkills(),
        )
        .subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  String? _resolveAvatarUrl(String? raw) {
    if (raw == null || raw.startsWith('http')) return raw;
    return _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .getPublicUrl(raw);
  }

  Future<String?> addSkill(Skill skill) async {
    try {
      await _client
          .from(SupabaseConstants.skillsTable)
          .insert(skill.toJson());
      await loadSkills();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
