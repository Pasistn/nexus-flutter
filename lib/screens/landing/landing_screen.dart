import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/skill.dart';
import '../../providers/skills_provider.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/skill_map.dart';
import '../../widgets/user_avatar.dart';
import '../auth/auth_screen.dart';
import '../legal/privacy_policy_screen.dart';

const _germany = LatLng(51.1657, 10.4515);

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _search = TextEditingController();
  Skill? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final skills = context.read<SkillsProvider>();
      _search.text = skills.query;
      skills.load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openAuth({bool register = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuthScreen(startWithRegister: register),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillsProvider>();
    final skills = provider.filtered(ignoreType: true);

    return Scaffold(
      backgroundColor: kBackdrop,
      body: SafeArea(
        child: Column(
          children: [
            _NavBar(onJoin: () => _openAuth(register: true)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _Hero(),
                  _SearchBar(controller: _search, onChanged: provider.setQuery),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 340,
                    child: Stack(
                      children: [
                        SkillMap(
                          skills: skills,
                          initialCenter: _germany,
                          initialZoom: 5.5,
                          onSkillTap: (s) => setState(() => _selected = s),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: _LiveCounter(count: skills.length),
                        ),
                        if (_selected != null)
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: _PreviewCard(
                              skill: _selected!,
                              onClose: () => setState(() => _selected = null),
                              onContact: _openAuth,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const _Features(),
                  const _Community(),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                      child: const Text(
                        'Datenschutz',
                        style: TextStyle(color: kTextMuted, fontSize: 12.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: kBorder)),
      ),
      child: Row(
        children: [
          const NexusLogo(size: 38),
          const SizedBox(width: 10),
          const Text(
            'NEXUS',
            style: TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onJoin,
            style: FilledButton.styleFrom(
              backgroundColor: kTextPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontFamily: kFontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            child: const Text('MITMACHEN'),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    const headline = TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      fontStyle: FontStyle.italic,
      height: 1.1,
      letterSpacing: -0.5,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: const Column(
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'TAUSCHE SKILLS.\n',
                  style: TextStyle(color: kTextPrimary),
                ),
                TextSpan(text: 'NICHT GELD.', style: TextStyle(color: kPrimary)),
              ],
            ),
            textAlign: TextAlign.center,
            style: headline,
          ),
          SizedBox(height: 12),
          Text(
            'Das Live-Radar für Nachbarschaftshilfe: Finde Leute in deiner Nähe, '
            'lerne etwas Neues und biete im Gegenzug an, was du selbst kannst.',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: kTextMuted, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                maxLength: 100,
                style: const TextStyle(color: kTextPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: 'Suche Skills, z. B. Gitarre …',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                ),
              ),
            ),
            const Icon(Icons.location_on_outlined, color: kTextMuted, size: 17),
            const SizedBox(width: 4),
            const Text(
              'Deutschland',
              style: TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveCounter extends StatelessWidget {
  const _LiveCounter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: kSuccess,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count Skills live',
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.skill,
    required this.onClose,
    required this.onContact,
  });

  final Skill skill;
  final VoidCallback onClose;
  final VoidCallback onContact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(url: skill.avatarUrl, name: skill.userName, radius: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      skill.userName ?? '',
                      style: const TextStyle(color: kTextSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: kTextMuted, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            skill.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContact,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Anmelden zum Kontaktieren'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Features extends StatelessWidget {
  const _Features();

  static const _items = [
    (
      Icons.radar_rounded,
      Color(0xFFEDE9FE),
      'LOKAL & LIVE',
      'Das Radar zeigt dir in Echtzeit, wer in deiner Umgebung etwas anbietet oder sucht.',
    ),
    (
      Icons.verified_user_outlined,
      Color(0xFFDBEAFE),
      'FAIR & SICHER',
      'Echte Bewertungen nach jedem Tausch. Du entscheidest, wen du triffst.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, bg, title, text) in _items)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: kPrimary, size: 26),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Community extends StatelessWidget {
  const _Community();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          const Text(
            'COMMUNITY',
            style: TextStyle(
              color: Color(0xFFCBD5E1),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              children: [
                Text('🌱', style: TextStyle(fontSize: 36)),
                SizedBox(height: 12),
                Text(
                  'Sei einer der Ersten!',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nexus wächst gerade. Registrier dich und hilf mit, eine '
                  'Nachbarschaft aufzubauen, in der Wissen geteilt wird.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
