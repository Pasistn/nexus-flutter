import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/skill_request_provider.dart';
import '../../models/category.dart' show SkillCategory;
import '../../providers/category_provider.dart';
import '../../providers/skills_provider.dart';
import '../../screens/auth/auth_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/skills/add_skill_screen.dart';
import '../../widgets/skill_card.dart';
import '../../widgets/star_rating_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(48.1351, 11.5820);
  bool _hasUserLocation = false;
  int _currentIndex = 0;
  Skill? _selectedSkill;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final skills = context.read<SkillsProvider>();
    await skills.loadSkills();
    context.read<CategoryProvider>().loadCategories();

    final profile = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      await profile.loadProfile(auth.currentUser!.id);
      if (profile.profile?.homeLat != null) {
        _moveTo(LatLng(profile.profile!.homeLat!, profile.profile!.homeLng!));
      } else {
        await _tryGetCurrentLocation();
      }

      // Load chat and request data
      context.read<ChatProvider>().loadConversations();
      context
          .read<SkillRequestProvider>()
          .loadRequests(auth.currentUser!.id);
    } else {
      await _tryGetCurrentLocation();
    }
  }

  Future<void> _tryGetCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      _moveTo(LatLng(pos.latitude, pos.longitude));
    } catch (_) {}
  }

  void _moveTo(LatLng latlng) {
    setState(() {
      _center = latlng;
      _hasUserLocation = true;
    });
    _mapController.move(latlng, 12);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>().profile;
    final skillsProv = context.watch<SkillsProvider>();
    final pendingCount =
        context.watch<SkillRequestProvider>().pendingCount;

    final bool locationKnown =
        profile?.homeLat != null || _hasUserLocation;
    final filteredSkills = skillsProv.filteredSkills(
      userLat: locationKnown ? (profile?.homeLat ?? _center.latitude) : null,
      userLng: locationKnown ? (profile?.homeLng ?? _center.longitude) : null,
    );

    return Scaffold(
      backgroundColor: kBgDark,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildRadarTab(filteredSkills, profile),
          _buildSkillsTab(filteredSkills, skillsProv),
          if (auth.isAuthenticated)
            const ChatListScreen()
          else
            _buildLoginPrompt(),
          if (auth.isAuthenticated)
            const ProfileScreen()
          else
            _buildLoginPrompt(),
        ],
      ),
      bottomNavigationBar:
          _buildBottomNav(auth, pendingCount),
      floatingActionButton: auth.isAuthenticated && _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openAddSkill(context),
              backgroundColor: kNeonOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Skill anbieten',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  Widget _buildRadarTab(List<Skill> skills, Profile? profile) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 12,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.nexus.app',
              additionalOptions: const {
                'attribution': '© OpenStreetMap contributors',
              },
            ),
            MarkerLayer(markers: _buildMarkers(skills, profile)),
          ],
        ),
        _buildRadarOverlay(skills),
        if (_selectedSkill != null) _buildSkillPopup(_selectedSkill!),
      ],
    );
  }

  List<Marker> _buildMarkers(List<Skill> skills, Profile? profile) {
    final markers = <Marker>[];

    if (profile?.homeLat != null) {
      markers.add(
        Marker(
          point: LatLng(profile!.homeLat!, profile.homeLng!),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              decoration: BoxDecoration(
                color: kNeonOrange,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: kNeonOrange.withOpacity(0.5),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.home, color: Colors.white, size: 20),
            ),
          ),
        ),
      );
    }

    for (final skill in skills) {
      markers.add(
        Marker(
          point: LatLng(skill.lat, skill.lng),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _selectSkill(skill),
            child: Container(
              decoration: BoxDecoration(
                color: kBgCard,
                shape: BoxShape.circle,
                border: Border.all(color: kNeonOrange, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.bolt, color: kNeonOrange, size: 22),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildRadarOverlay(List<Skill> skills) {
    final skillsProv = context.watch<SkillsProvider>();
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kBgDark.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kNeonOrange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt,
                        color: Colors.black, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text('Nexus Radar',
                      style: TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kSuccess.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: kSuccess.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: kSuccess,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('${skills.length} Skills',
                            style: const TextStyle(
                                color: kSuccess,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                onChanged: skillsProv.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Skills suchen...',
                  prefixIcon:
                      Icon(Icons.search, color: kTextMuted, size: 18),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.radar, color: kTextMuted, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    skillsProv.radiusKm >= 500
                        ? 'Bundesweit'
                        : '${skillsProv.radiusKm.round()} km',
                    style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  Expanded(
                    child: Slider(
                      value: skillsProv.radiusKm.clamp(1, 500),
                      min: 1,
                      max: 500,
                      onChanged: skillsProv.setRadius,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkillPopup(Skill skill) {
    final summary =
        context.watch<RatingsProvider>().getSummary(skill.userId);
    final auth = context.watch<AuthProvider>();
    final currentUserId = auth.currentUser?.id;
    final canRate =
        auth.isAuthenticated && currentUserId != skill.userId;
    final canRequest =
        auth.isAuthenticated && currentUserId != skill.userId;

    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: kNeonOrange.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: kBgCardElevated,
                  backgroundImage: skill.avatarUrl != null
                      ? NetworkImage(skill.avatarUrl!)
                      : null,
                  child: skill.avatarUrl == null
                      ? Text(
                          skill.userName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: const TextStyle(
                              color: kNeonOrange,
                              fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skill.skillTitle,
                          style: const TextStyle(
                              color: kTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      Text(skill.userName ?? '',
                          style: const TextStyle(
                              color: kTextSecondary, fontSize: 12)),
                      const SizedBox(height: 2),
                      if (summary != null)
                        StarRatingBar(
                          rating: summary.avg,
                          count: summary.count,
                          size: 13,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(skill.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: kTextSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (canRate)
                        _popupBtn(
                          icon: Icons.star_outline_rounded,
                          label: 'Bewerten',
                          color: kNeonOrange,
                          onTap: () => _openRatingDialog(skill),
                        ),
                      if (canRequest)
                        _popupBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Nachricht',
                          color: kNeonOrange,
                          onTap: () => _openDirectChat(skill),
                        ),
                      if (canRequest)
                        _popupBtn(
                          icon: Icons.send_rounded,
                          label: 'Anfragen',
                          color: kSuccess,
                          onTap: () => _openRequestDialog(skill),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _selectedSkill = null),
                  child: const Icon(Icons.close,
                      color: kTextMuted, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsTab(
      List<Skill> skills, SkillsProvider skillsProv) {
    final auth = context.watch<AuthProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text('Skills entdecken'),
          backgroundColor: kBgDark,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                onChanged: skillsProv.setQuery,
                decoration: const InputDecoration(
                  hintText: 'Skills suchen...',
                  prefixIcon:
                      Icon(Icons.search, color: kTextMuted, size: 18),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(color: kTextPrimary, fontSize: 14),
              ),
            ),
          ),
        ),
        if (categories.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildCategoryFilter(categories, skillsProv),
          ),
        skillsProv.loading
            ? const SliverFillRemaining(
                child: Center(
                    child: CircularProgressIndicator(color: kNeonOrange)))
            : skillsProv.error != null
                ? SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.cloud_off,
                                color: kError, size: 48),
                            const SizedBox(height: 12),
                            const Text('Fehler beim Laden',
                                style: TextStyle(
                                    color: kTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(skillsProv.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: kTextSecondary, fontSize: 12)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: skillsProv.loadSkills,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Erneut versuchen'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : skills.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off,
                                  color: kTextMuted, size: 48),
                              SizedBox(height: 12),
                              Text('Keine Skills gefunden',
                                  style:
                                      TextStyle(color: kTextSecondary)),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildSkillListItem(
                                ctx, skills[i], auth),
                            childCount: skills.length,
                          ),
                        ),
                      ),
      ],
    );
  }

  Widget _buildCategoryFilter(
      List<SkillCategory> categories, SkillsProvider skillsProv) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildFilterChip(
            label: 'Alle',
            icon: null,
            selected: skillsProv.selectedCategoryId == null,
            onTap: () => skillsProv.setCategory(null),
          ),
          ...categories.map((cat) => _buildFilterChip(
                label: cat.name,
                icon: cat.icon,
                selected: skillsProv.selectedCategoryId == cat.id,
                onTap: () => skillsProv.setCategory(cat.id),
              )),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? kNeonOrange.withOpacity(0.15) : kBgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kNeonOrange : kBorderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? kNeonOrange : kTextSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillListItem(
      BuildContext ctx, Skill skill, AuthProvider auth) {
    final currentUserId = auth.currentUser?.id;
    final canInteract =
        auth.isAuthenticated && currentUserId != skill.userId;

    const bottomRadius = BorderRadius.only(
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    );

    return Column(
      children: [
        SkillCardWidget(skill: skill),
        if (canInteract)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openDirectChat(skill),
                    icon: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 15),
                    label: const Text('Nachricht'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                          borderRadius: bottomRadius),
                    ),
                  ),
                ),
                const SizedBox(width: 1),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openRequestDialog(skill),
                    icon: const Icon(Icons.send_rounded, size: 15),
                    label: const Text('Anfragen'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: const RoundedRectangleBorder(
                          borderRadius: bottomRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kNeonOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: kNeonOrange, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Melde dich an',
                style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Erstelle ein Profil, um Skills anzubieten und zu tauschen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: kTextSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const AuthScreen())),
              child: const Text('Anmelden / Registrieren'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AuthProvider auth, int pendingCount) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (i) => setState(() => _currentIndex = i),
      backgroundColor: kBgCard,
      selectedItemColor: kNeonOrange,
      unselectedItemColor: kTextMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
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
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded),
              if (pendingCount > 0)
                Positioned(
                  right: -6,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: kError,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: auth.isAuthenticated
              ? const Icon(Icons.person_rounded)
              : const Icon(Icons.login_rounded),
          label: auth.isAuthenticated ? 'Profil' : 'Anmelden',
        ),
      ],
    );
  }

  void _selectSkill(Skill skill) {
    setState(() => _selectedSkill = skill);
    context.read<RatingsProvider>().loadForUser(skill.userId);
  }

  void _openAddSkill(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddSkillScreen()),
    );
  }

  Widget _popupBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14, color: color),
        label: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          backgroundColor: color.withOpacity(0.1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
        ),
      );

  Future<void> _openDirectChat(Skill skill) async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte anmelden um Nachrichten zu senden')),
      );
      return;
    }

    final profile = context.read<ProfileProvider>().profile;
    final chatProv = context.read<ChatProvider>();

    final (convId, err) = await chatProv.createDirectChat(
      currentUserId: auth.currentUser!.id,
      currentUserName: profile?.userName ?? 'Anonym',
      currentUserAvatar: profile?.avatarUrl,
      otherUserId: skill.userId,
      otherUserName: skill.userName ?? 'Anonym',
      otherUserAvatar: skill.avatarUrl,
      skillId: skill.id,
    );

    if (!mounted) return;

    if (err != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler: $err')));
      return;
    }

    final conv = chatProv.conversations.firstWhere((c) => c.id == convId!);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ChatScreen(conversation: conv)));
  }

  void _openRequestDialog(Skill skill) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Bitte anmelden um Anfragen zu senden')),
      );
      return;
    }

    final messageCtrl = TextEditingController();
    bool sending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kBgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Skill anfragen',
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  skill.skillTitle,
                  style: const TextStyle(
                      color: kNeonOrange,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: messageCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Nachricht (optional)',
                    hintText: 'Wann, wo, worum geht es?',
                  ),
                  style: const TextStyle(color: kTextPrimary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending
                        ? null
                        : () async {
                            setModalState(() => sending = true);
                            final profile =
                                context.read<ProfileProvider>().profile;
                            final err = await context
                                .read<SkillRequestProvider>()
                                .createRequest(
                                  skillId: skill.id,
                                  skillTitle: skill.skillTitle,
                                  requesterId: auth.currentUser!.id,
                                  requesterName: profile?.userName,
                                  requesterAvatar: profile?.avatarUrl,
                                  skillOwnerId: skill.userId,
                                  message: messageCtrl.text.trim().isEmpty
                                      ? null
                                      : messageCtrl.text.trim(),
                                );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err == null
                                    ? 'Anfrage gesendet!'
                                    : 'Fehler: $err'),
                                backgroundColor:
                                    err == null ? kSuccess : kError,
                              ),
                            );
                          },
                    child: sending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Anfrage senden'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openRatingDialog(Skill skill) {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte anmelden um zu bewerten')),
      );
      return;
    }
    if (auth.currentUser!.id == skill.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Du kannst dich nicht selbst bewerten')),
      );
      return;
    }

    int selectedRating = 0;
    final commentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kBgCard,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kBorderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '${skill.userName ?? "Person"} bewerten',
                  style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  skill.skillTitle,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 13),
                ),
                const SizedBox(height: 24),
                InteractiveStarRating(
                  initialRating: selectedRating,
                  size: 40,
                  onChanged: (v) =>
                      setModalState(() => selectedRating = v),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: commentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Kommentar (optional)',
                    hintText: 'Wie war die Zusammenarbeit?',
                  ),
                  style: const TextStyle(color: kTextPrimary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedRating == 0
                        ? null
                        : () async {
                            final profile =
                                context.read<ProfileProvider>().profile;
                            final err = await context
                                .read<RatingsProvider>()
                                .submitRating(
                                  ratedUserId: skill.userId,
                                  rating: selectedRating,
                                  raterName: profile?.userName,
                                  comment:
                                      commentCtrl.text.trim().isEmpty
                                          ? null
                                          : commentCtrl.text.trim(),
                                  skillId: skill.id,
                                );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(err == null
                                    ? 'Bewertung gespeichert!'
                                    : 'Fehler: $err'),
                              ),
                            );
                          },
                    child: const Text('Bewertung abgeben'),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
