import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../models/profile.dart';

class ProfileProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  static const maxNameLength = 50;
  static const maxBioLength = 500;
  static const maxAddressLength = 300;
  static const _maxAvatarBytes = 2 * 1024 * 1024;
  static const _imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  Profile? _profile;
  bool _loading = false;
  String? _error;

  Profile? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final row = await _client
          .from(Tables.profiles)
          .select()
          .eq('id', userId)
          .maybeSingle();
      _profile = row == null ? Profile(id: userId) : Profile.fromJson(row);
    } catch (e) {
      _error = friendlyError(e);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> save(Profile draft, {XFile? avatar}) async {
    if ((draft.userName?.length ?? 0) > maxNameLength) {
      return 'Der Name darf höchstens $maxNameLength Zeichen lang sein.';
    }
    if ((draft.bio?.length ?? 0) > maxBioLength) {
      return 'Die Bio darf höchstens $maxBioLength Zeichen lang sein.';
    }

    var next = draft;
    if (avatar != null) {
      final (path, err) = await _uploadAvatar(draft.id, avatar);
      if (err != null) return err;
      next = Profile(
        id: draft.id,
        userName: draft.userName,
        bio: draft.bio,
        avatarUrl: path,
        homeAddress: draft.homeAddress,
        homeLat: draft.homeLat,
        homeLng: draft.homeLng,
      );
    }

    try {
      await _client.from(Tables.profiles).upsert(next.toJson());
    } catch (e) {
      return friendlyError(e);
    }

    _profile = next;
    notifyListeners();
    if (avatar != null) _pruneOldAvatars(next.id, keep: next.avatarUrl!);
    return null;
  }

  Future<(String?, String?)> _uploadAvatar(String userId, XFile file) async {
    final ext = file.name.split('.').last.toLowerCase();
    final contentType = _imageTypes[ext];
    if (contentType == null) {
      return (null, 'Bitte wähle ein JPG-, PNG- oder WebP-Bild.');
    }

    try {
      final bytes = await file.readAsBytes();
      if (bytes.length > _maxAvatarBytes) {
        return (null, 'Das Bild ist zu groß (max. 2 MB).');
      }

      final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from(Buckets.avatars).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: contentType),
          );
      return (path, null);
    } catch (e) {
      return (null, friendlyError(e));
    }
  }

  Future<void> _pruneOldAvatars(String userId, {required String keep}) async {
    try {
      final bucket = _client.storage.from(Buckets.avatars);
      final files = await bucket.list(path: userId);
      final stale = [
        for (final f in files)
          if ('$userId/${f.name}' != keep) '$userId/${f.name}',
      ];
      if (stale.isNotEmpty) await bucket.remove(stale);
    } catch (_) {}
  }

  void clear() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
