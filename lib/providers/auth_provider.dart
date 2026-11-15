import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../services/push_notification_service.dart';

typedef SignUpResult = ({String? error, bool needsConfirmation});

class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _authSub = _client.auth.onAuthStateChange.listen(_onAuthChange);
    _tokenSub = PushNotificationService.onTokenRefresh
        .listen((_) => _registerDevice());
    if (isAuthenticated) _registerDevice();
  }

  static const minPasswordLength = 8;

  final _client = Supabase.instance.client;
  late final StreamSubscription<AuthState> _authSub;
  late final StreamSubscription<String> _tokenSub;
  String? _deviceToken;

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  void _onAuthChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedIn) _registerDevice();
    notifyListeners();
  }

  Future<void> _registerDevice() async {
    if (!isAuthenticated || !PushNotificationService.isAvailable) return;
    try {
      final token = await PushNotificationService.token();
      if (token == null) return;
      _deviceToken = token;
      await _client.rpc('upsert_device_token', params: {
        'p_token': token,
        'p_platform': PushNotificationService.platform,
      });
    } catch (e) {
      debugPrint('[push] token registration failed: $e');
    }
  }

  Future<void> _unregisterDevice() async {
    final token = _deviceToken;
    if (token == null) return;
    _deviceToken = null;
    try {
      await _client.from(Tables.deviceTokens).delete().eq('fcm_token', token);
    } catch (_) {}
  }

  Future<SignUpResult> signUp(String email, String password) async {
    if (password.length < minPasswordLength) {
      return (
        error: 'Das Passwort muss mindestens $minPasswordLength Zeichen lang sein.',
        needsConfirmation: false,
      );
    }
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: kIsWeb ? Uri.base.origin : null,
      );
      return (error: null, needsConfirmation: res.session == null);
    } catch (e) {
      return (error: friendlyError(e), needsConfirmation: false);
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<void> signOut() async {
    await _unregisterDevice();
    await _client.auth.signOut();
  }

  Future<String?> deleteAccount() async {
    final uid = userId;
    if (uid == null) return 'Nicht angemeldet.';

    try {
      await _unregisterDevice();
      await _removeAvatarFolder(uid);
      await _client.rpc('delete_user');
      await _client.auth.signOut();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<void> _removeAvatarFolder(String uid) async {
    try {
      final bucket = _client.storage.from(Buckets.avatars);
      final files = await bucket.list(path: uid);
      if (files.isEmpty) return;
      await bucket.remove([for (final f in files) '$uid/${f.name}']);
    } catch (_) {}
  }

  @override
  void dispose() {
    _authSub.cancel();
    _tokenSub.cancel();
    super.dispose();
  }
}
