import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  AuthProvider() {
    _client.auth.onAuthStateChange.listen((_) => notifyListeners());
  }

  Future<String?> signUp(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
