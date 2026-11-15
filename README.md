# Nexus

**Skills tauschen statt Geld ausgeben.** Nexus ist eine Tauschbörse für Nachbarschaftshilfe: Leute tragen ein, was sie können („Gitarrenunterricht“) oder was sie suchen („Hilfe beim Fahrrad“), und finden sich über eine Live-Karte in ihrer Umgebung. Kontakt läuft über Anfragen und einen Echtzeit-Chat, nach dem Treffen bewertet man sich gegenseitig.

Die App läuft als Android-, iOS- und Web-App aus einer Codebasis (Flutter). Die Web-Version wird als Docker-Container ausgeliefert.

## Features

- **Radar** – Karte (OpenStreetMap) mit allen Angeboten und Gesuchen im einstellbaren Umkreis, Live-Updates per Supabase Realtime
- **Skills-Liste** – Suche, Filter nach Typ (Angebot/Gesuch) und Kategorie
- **Anfragen** – Skill anfragen, annehmen/ablehnen; beim Annehmen öffnet sich automatisch ein Chat
- **Chat** – 1:1- und Gruppenchats in Echtzeit
- **Bewertungen** – 1–5 Sterne mit Kommentar, Durchschnitt pro Person
- **Profil** – Avatar-Upload, Bio, Heimatort als Radar-Zentrum, eigene Einträge verwalten, Konto löschen
- **Moderation** – Einträge melden
- **Push** (mobil, optional) – Firebase Cloud Messaging über eine Supabase Edge Function

## Tech-Stack

| Bereich | Technik |
|---|---|
| App | Flutter 3.44, Dart 3, Provider |
| Backend | Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) |
| Karte & Geocoding | flutter_map, OpenStreetMap, Nominatim |
| Push | Firebase Cloud Messaging, flutter_local_notifications |
| Deployment | Docker (Flutter-Build → nginx), docker compose, GitHub Actions |

## Architektur

```
lib/
├── main.dart              Einstieg: Konfiguration prüfen, Supabase + Push initialisieren
├── app.dart               Provider-Setup, Theme, AuthGate (Landing ↔ Home)
├── core/                  Konfiguration, Theme, kleine Hilfsfunktionen
├── models/                Reine Datenklassen mit fromJson/toJson
├── providers/             State + Datenzugriff (ein ChangeNotifier pro Bereich)
├── services/              Geocoding, Standort, Push
├── screens/               UI, nach Feature gruppiert
└── widgets/               Wiederverwendbare UI-Bausteine

supabase/
├── migrations/            Schema, Row Level Security, Trigger, RPCs
└── functions/send-push/   Edge Function für FCM
```

**Sicherheit liegt in der Datenbank, nicht im Client.** Der Anon-Key steckt in jedem Build, also kann jeder die REST-API direkt aufrufen. Deshalb:

- Row Level Security auf allen Tabellen; Chats sind nur für Mitglieder sichtbar.
- Felder wie Absendername, Anfrage-Empfänger oder Bewerter werden per Trigger aus der Session gesetzt und lassen sich nicht fälschen.
- Chats und Gruppen entstehen ausschließlich über `SECURITY DEFINER`-Funktionen (`create_direct_chat`, `create_group_chat`, `accept_skill_request`).
- Öffentliche Profildaten (Name, Bio, Avatar) liegen in `profiles`, die Heimatadresse getrennt davon in `profile_private`, die nur der Besitzer lesen kann.
- Skill-Koordinaten werden serverseitig auf ~100 m gerundet.
- Einfache Rate-Limits (Nachrichten, Anfragen, neue Einträge) direkt in den Triggern.

## Lokal starten

Voraussetzungen: Flutter ≥ 3.44 und ein Supabase-Projekt.

1. **Datenbank einrichten** – die Dateien aus `supabase/migrations/` der Reihe nach im SQL-Editor ausführen oder mit der CLI:
   ```bash
   npx supabase link --project-ref <project-ref>
   npx supabase db push
   ```
2. **Konfiguration** – `env.example.json` nach `env.json` kopieren und URL + Anon-Key eintragen (Supabase → Project Settings → API). Die Firebase-Felder können leer bleiben, dann ist Push einfach deaktiviert.
3. **Starten**
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env.json
   flutter run -d chrome --dart-define-from-file=env.json
   ```

## Deployment auf einem eigenen Server

Die Web-Version wird im Container gebaut und von nginx ausgeliefert.

```bash
git clone https://github.com/<user>/nexus-flutter.git
cd nexus-flutter
cp .env.example .env
nano .env
docker compose up -d --build
```

Der Container lauscht danach nur lokal auf `127.0.0.1:8080` (Port über `PORT` in `.env` änderbar) und ist von außen nicht direkt erreichbar.

**HTTPS ist Pflicht**, weil Browser Standortabfragen nur über HTTPS erlauben. Davor gehört deshalb ein Reverse Proxy, z. B. Caddy, der das Zertifikat automatisch holt:

```
nexus.example.com {
    reverse_proxy localhost:8080
}
```

**In Supabase eintragen** (Authentication → URL Configuration): die eigene Domain als *Site URL* und unter *Redirect URLs*, damit die Bestätigungsmails auf die richtige Seite zurückführen.

Update ausrollen:

```bash
git pull && docker compose up -d --build
```

## Push-Benachrichtigungen (optional)

1. Firebase-Projekt anlegen, Android-/iOS-App registrieren, Werte in `env.json` eintragen.
2. Edge Function deployen:
   ```bash
   npx supabase functions deploy send-push --no-verify-jwt
   npx supabase secrets set FCM_PROJECT_ID=... PUSH_TRIGGER_SECRET=... FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)"
   ```
3. URL und Secret im Vault hinterlegen, damit die Trigger die Function aufrufen können:
   ```sql
   select vault.create_secret('https://<project-ref>.supabase.co/functions/v1/send-push', 'push_function_url');
   select vault.create_secret('<gleicher Wert wie PUSH_TRIGGER_SECRET>', 'push_trigger_secret');
   ```

Ohne diese Schritte funktioniert alles andere ganz normal – die Trigger überspringen den Versand dann einfach.

## Android-Release

```bash
keytool -genkey -v -keystore android/nexus-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nexus
cp android/key.properties.template android/key.properties
flutter build appbundle --dart-define-from-file=env.json
```

`key.properties`, Keystore, `env.json` und `google-services.json` sind in `.gitignore` und landen nie im Repo.

## Tests

```bash
flutter analyze
flutter test
```

Die CI (`.github/workflows/ci.yml`) führt Analyse, Tests, Web-Build und Docker-Build bei jedem Push aus.
