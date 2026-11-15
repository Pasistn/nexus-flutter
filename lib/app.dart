import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/ratings_provider.dart';
import 'providers/skill_request_provider.dart';
import 'providers/skills_provider.dart';
import 'screens/home/home_screen.dart';
import 'screens/landing/landing_screen.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => SkillsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => RatingsProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SkillRequestProvider()),
      ],
      child: MaterialApp(
        title: 'Nexus – Skills tauschen',
        debugShowCheckedModeBanner: false,
        theme: buildNexusTheme(),
        builder: (context, child) => _PhoneFrame(child: child!),
        home: const AuthGate(),
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  static const _maxWidth = 520.0;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= _maxWidth + 80) return child;

    return ColoredBox(
      color: kBackdrop,
      child: Center(
        child: Container(
          width: _maxWidth,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 40,
              ),
            ],
          ),
          child: MediaQuery(
            data: mq.copyWith(size: Size(_maxWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthProvider _auth = context.read<AuthProvider>();
  late String? _userId = _auth.userId;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_handleAuthChange);
  }

  @override
  void dispose() {
    _auth.removeListener(_handleAuthChange);
    super.dispose();
  }

  void _handleAuthChange() {
    final next = _auth.userId;
    if (next == _userId) return;

    final previous = _userId;
    _userId = next;
    if (previous == null) return;

    context.read<ProfileProvider>().clear();
    context.read<ChatProvider>().clear();
    context.read<SkillRequestProvider>().clear();
    context.read<RatingsProvider>().clear();
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthProvider, bool>((a) => a.isAuthenticated);
    return signedIn ? const HomeScreen() : const LandingScreen();
  }
}

class MissingConfigApp extends StatelessWidget {
  const MissingConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildNexusTheme(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Supabase ist nicht konfiguriert.\n\n'
              'Starte die App mit\n'
              'flutter run --dart-define-from-file=env.json',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSecondary, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
