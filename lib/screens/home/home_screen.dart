import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../providers/skills_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/bottom_sheet.dart';
import '../../widgets/feedback.dart';
import '../../widgets/skill_type_style.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';
import '../skills/add_skill_screen.dart';
import 'radar_tab.dart';
import 'skills_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  LatLng? _deviceLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final userId = context.read<AuthProvider>().userId;
    final profile = context.read<ProfileProvider>();

    context.read<CategoryProvider>().load();
    context.read<SkillsProvider>().load();
    if (userId == null) return;

    context.read<ChatProvider>().loadConversations();
    context.read<SkillRequestProvider>().load(userId);

    await profile.load(userId);
    if (!mounted || (profile.profile?.hasHome ?? false)) return;

    final here = await LocationService.tryCurrent();
    if (mounted && here != null) setState(() => _deviceLocation = here);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final pending = context.select<SkillRequestProvider, int>((r) => r.pendingCount);

    final home = profile != null && profile.hasHome
        ? LatLng(profile.homeLat!, profile.homeLng!)
        : null;
    final origin = home ?? _deviceLocation;

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          RadarTab(origin: origin, home: home),
          SkillsTab(origin: origin),
          const ChatListScreen(),
          const ProfileScreen(),
        ],
      ),
      floatingActionButton: _tab < 2
          ? FloatingActionButton.extended(
              heroTag: 'add-skill',
              onPressed: _chooseSkillType,
              icon: const Icon(Icons.add),
              label: const Text(
                'Skill eintragen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded),
            label: 'Radar',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Skills',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: pending > 0,
              label: Text('$pending'),
              backgroundColor: kError,
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Future<void> _chooseSkillType() async {
    final type = await showNexusSheet<SkillType>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetTitle(
            'Was möchtest du eintragen?',
            subtitle: 'Biete etwas an, das du kannst – oder such dir Hilfe.',
          ),
          const SizedBox(height: 20),
          _TypeOption(
            type: SkillType.offering,
            title: 'Skill anbieten',
            subtitle: 'Ich kann anderen bei etwas helfen.',
            onTap: () => Navigator.pop(ctx, SkillType.offering),
          ),
          const SizedBox(height: 12),
          _TypeOption(
            type: SkillType.searching,
            title: 'Skill suchen',
            subtitle: 'Ich suche jemanden, der mir hilft.',
            onTap: () => Navigator.pop(ctx, SkillType.searching),
          ),
        ],
      ),
    );
    if (type == null || !mounted) return;

    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AddSkillScreen(initialType: type)),
    );
    if (created == true && mounted) showSnack(context, 'Eintrag veröffentlicht!');
  }
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final SkillType type;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.14),
              child: Icon(type.icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}
