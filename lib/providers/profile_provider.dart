import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  Profile? _profile;
  bool _loading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProfile(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _client
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      _profile = data != null ? _normalizeProfile(data) : null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Profile _normalizeProfile(Map<String, dynamic> data) {
    final profile = Profile.fromJson(data);
    final raw = data['avatar_url'] as String?;
    if (raw == null || raw.startsWith('http')) return profile;
    final fullUrl = _client.storage
        .from(SupabaseConstants.avatarsBucket)
        .getPublicUrl(raw);
    return profile.copyWith(avatarUrl: fullUrl);
  }

  Future<String?> upsertProfile(Profile profile) async {
    try {
      await _client
          .from(SupabaseConstants.profilesTable)
          .upsert(profile.toJson());
      _profile = profile;
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> uploadAvatar(String userId, File file) async {
    try {
      final ext = file.path.split('.').last;
      final path = '$userId/avatar.$ext';

      await _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      final url = _client.storage
          .from(SupabaseConstants.avatarsBucket)
          .getPublicUrl(path);

      return url;
    } catch (e) {
      return null;
    }
  }

  void clear() {
    _profile = null;
    notifyListeners();
  }
}
