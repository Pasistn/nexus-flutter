import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const _firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const _firebaseBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _androidApiKey = String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static FirebaseOptions? get firebaseOptions {
    if (kIsWeb || _firebaseProjectId.isEmpty) return null;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android when _androidApiKey.isNotEmpty => const FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _firebaseSenderId,
          projectId: _firebaseProjectId,
          storageBucket: _firebaseBucket,
        ),
      TargetPlatform.iOS when _iosApiKey.isNotEmpty => const FirebaseOptions(
          apiKey: _iosApiKey,
          appId: _iosAppId,
          messagingSenderId: _firebaseSenderId,
          projectId: _firebaseProjectId,
          storageBucket: _firebaseBucket,
          iosBundleId: _iosBundleId,
        ),
      _ => null,
    };
  }
}
