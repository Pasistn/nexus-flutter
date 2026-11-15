import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _contact = 'support@nexus-app.de';

const _sections = <(String, String)>[
  (
    '1. Verantwortlicher',
    'Nexus ist ein nicht-kommerzielles Projekt. Bei Fragen zum Datenschutz '
        'erreichst du uns unter $_contact.',
  ),
  (
    '2. Welche Daten wir speichern',
    '• E-Mail-Adresse (Konto und Anmeldung)\n'
        '• Anzeigename, Profilbild und Bio (freiwillig)\n'
        '• Heimatort und Koordinaten (nur für dich sichtbar)\n'
        '• Deine Skill-Einträge inkl. ungefährem Standort (auf ca. 100 m gerundet)\n'
        '• Chatnachrichten, Anfragen und Bewertungen',
  ),
  (
    '3. Wofür',
    'Ausschließlich um die Funktionen der App bereitzustellen: Skill-Suche, '
        'Tauschbörse, Chat und Bewertungen. Wir verkaufen keine Daten und '
        'geben sie nicht an Werbenetzwerke weiter.',
  ),
  (
    '4. Wo die Daten liegen',
    'Die Daten werden bei Supabase (supabase.com) in der EU gespeichert. '
        'Kartenkacheln und Adresssuche kommen von OpenStreetMap.',
  ),
  (
    '5. Standort',
    'Der Standort wird nur abgefragt, während du die App benutzt – nie im '
        'Hintergrund. Du kannst den Zugriff jederzeit in den Einstellungen '
        'deines Geräts oder Browsers entziehen.',
  ),
  (
    '6. Deine Rechte',
    'Du hast das Recht auf Auskunft, Berichtigung, Löschung, Datenübertragbarkeit '
        'und Widerspruch. Dein Konto kannst du jederzeit selbst unter '
        'Profil → „Konto löschen“ entfernen – dabei werden alle Daten gelöscht.',
  ),
  (
    '7. Meldungen',
    'Unangemessene Einträge kannst du über „Melden“ direkt in der App melden. '
        'Wir prüfen Meldungen und entfernen Inhalte oder Konten bei Verstößen.',
  ),
  (
    '8. Cookies & Tracking',
    'Kein Tracking, keine Werbung, keine Analyse-Tools. Im Browser wird '
        'lediglich deine Anmeldesitzung lokal gespeichert.',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Datenschutz')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          for (final (title, body) in _sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 6),
              child: Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
            Text(
              body,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 13.5,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
