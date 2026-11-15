import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../core/utils/geo_utils.dart';
import '../models/skill.dart';

class SkillsProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  static const maxTitleLength = 100;
  static const maxDescriptionLength = 2000;
  static const maxRadiusKm = 500.0;
  static const _limit = 1000;

  List<Skill> _skills = [];
  bool _loading = false;
  String? _error;

  String _query = '';
  double _radiusKm = maxRadiusKm;
  String? _categoryId;
  SkillType? _type;

  RealtimeChannel? _channel;
  Timer? _reloadTimer;

  List<Skill> get all => _skills;
  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  double get radiusKm => _radiusKm;
  bool get isNationwide => _radiusKm >= maxRadiusKm;
  String? get categoryId => _categoryId;
  SkillType? get type => _type;

  List<Skill> filtered({LatLng? origin, bool ignoreType = false}) {
    final q = _query.trim().toLowerCase();
    return _skills.where((s) {
      if (!ignoreType && _type != null && s.type != _type) return false;
      if (_categoryId != null && s.categoryId != _categoryId) return false;
      if (q.isNotEmpty &&
          !s.title.toLowerCase().contains(q) &&
          !s.description.toLowerCase().contains(q) &&
          !(s.userName?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      if (origin != null &&
          !isNationwide &&
          distanceKm(origin.latitude, origin.longitude, s.lat, s.lng) >
              _radiusKm) {
        return false;
      }
      return true;
    }).toList();
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setRadius(double km) {
    _radiusKm = km;
    notifyListeners();
  }

  void setCategory(String? id) {
    _categoryId = id;
    notifyListeners();
  }

  void setType(SkillType? type) {
    _type = type;
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final rows = await _client
          .from(Tables.skills)
          .select('*, categories(id, name, icon)')
          .not('lat', 'is', null)
          .not('lng', 'is', null)
          .order('created_at', ascending: false)
          .limit(_limit);

      final avatars = await _avatarsFor(
        rows.map((r) => r['user_id']).whereType<String>().toSet(),
      );

      _skills = [
        for (final row in rows)
          Skill.fromJson({...row, 'avatar_url': avatars[row['user_id']]}),
      ];
      _error = null;
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }

    _channel ??= _client
        .channel('rt-skills')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: Tables.skills,
          callback: (_) {
            _reloadTimer?.cancel();
            _reloadTimer =
                Timer(const Duration(seconds: 1), () => load(silent: true));
          },
        )
        .subscribe();
  }

  Future<Map<String, String?>> _avatarsFor(Set<String> userIds) async {
    if (userIds.isEmpty) return const {};
    final rows = await _client
        .from(Tables.profiles)
        .select('id, avatar_url')
        .inFilter('id', userIds.toList());
    return {
      for (final r in rows) r['id'] as String: r['avatar_url'] as String?,
    };
  }

  Future<String?> add(Skill skill) async {
    if (skill.title.isEmpty || skill.title.length > maxTitleLength) {
      return 'Der Titel muss zwischen 1 und $maxTitleLength Zeichen lang sein.';
    }
    if (skill.description.isEmpty ||
        skill.description.length > maxDescriptionLength) {
      return 'Die Beschreibung muss zwischen 1 und $maxDescriptionLength Zeichen lang sein.';
    }

    try {
      await _client.from(Tables.skills).insert(skill.toInsertJson());
    } catch (e) {
      return friendlyError(e);
    }
    await load(silent: true);
    return null;
  }

  List<Skill> ownedBy(String userId) =>
      _skills.where((s) => s.userId == userId).toList();

  Future<String?> remove(String skillId) async {
    try {
      await _client.from(Tables.skills).delete().eq('id', skillId);
    } catch (e) {
      return friendlyError(e);
    }
    _skills = _skills.where((s) => s.id != skillId).toList();
    notifyListeners();
    return null;
  }

  Future<String?> report(String skillId, String reason) async {
    try {
      await _client.from(Tables.skillReports).insert({
        'skill_id': skillId,
        'reporter_id': _client.auth.currentUser?.id,
        'reason': reason,
      });
      return null;
    } on PostgrestException catch (e) {
      if (e.code == '23505') return 'Du hast diesen Eintrag bereits gemeldet.';
      return friendlyError(e);
    } catch (e) {
      return friendlyError(e);
    }
  }

  @override
  void dispose() {
    _reloadTimer?.cancel();
    if (_channel != null) _client.removeChannel(_channel!);
    super.dispose();
  }
}
