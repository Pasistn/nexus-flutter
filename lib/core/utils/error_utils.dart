import 'package:flutter/foundation.dart';
import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

String friendlyError(Object error) {
  if (kDebugMode) debugPrint('[nexus] $error');

  if (error is PostgrestException && error.code == 'P0001') {
    return error.message;
  }

  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'E-Mail oder Passwort ist falsch.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
    }
    if (msg.contains('already registered')) {
      return 'Diese E-Mail-Adresse wird bereits verwendet.';
    }
    if (error.statusCode == '429' || msg.contains('rate limit')) {
      return 'Zu viele Versuche. Bitte warte einen Moment.';
    }
    if (msg.contains('password')) {
      return 'Das Passwort erfüllt die Anforderungen nicht.';
    }
    return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
  }

  if (error is ClientException) return 'Keine Internetverbindung.';

  return 'Etwas ist schiefgelaufen. Bitte versuche es erneut.';
}
