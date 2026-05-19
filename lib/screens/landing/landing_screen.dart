import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../models/skill.dart';
import '../../providers/skills_provider.dart';
import '../auth/auth_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  static const _kBlue = Color(0xFF2563EB);
  static const _kDark = Color(0xFF111827);
  static const _kGray = Color(0xFF6B7280);
  static const _kBorder = Color(0xFFE5E7EB);
  static const _kGreen = Color(0xFF22C55E);
  static const _kBg = Color(0xFFF1F5F9);

  final _searchController = TextEditingController();
  Skill? _selectedSkill;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SkillsProvider>().loadSkills();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skillsProv = context.watch<SkillsProvider>();
    final skills = skillsProv.query.isNotEmpty
        ? skillsProv.filteredSkills()
        : skillsProv.allSkills;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(),
                    _buildSearchCard(skillsProv),
                    const SizedBox(height: 16),
                    _buildMap(skills),
                    _buildFeatures(),
                    _buildWallOfLove(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _kBorder)),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: _kGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEXUS',
                style: GoogleFonts.poppins(
                  color: _kBlue,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _openAuth(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _kDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'NEXUS BEITRETEN',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'TAUSCHE SKILLS.\n',
                  style: GoogleFonts.poppins(
                    color: _kDark,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'NICHT GELD.',
                  style: GoogleFonts.poppins(
                    color: _kBlue,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Willkommen im Live-Radar für nachbarschaftliche Hilfe. Finde Experten in deiner Nähe, lerne Neues und biete deine eigenen Fähigkeiten im Tausch an.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: _kGray,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard(SkillsProvider skillsProv) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: skillsProv.setQuery,
                decoration: InputDecoration(
                  hintText: 'Suche Skills, z.B. Gitarre...',
                  hintStyle: GoogleFonts.poppins(
                      color: const Color(0xFF9CA3AF), fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
                style: GoogleFonts.poppins(color: _kDark, fontSize: 13),
              ),
            ),
            Container(width: 1, height: 20, color: _kBorder),
            const SizedBox(width: 10),
            const Icon(Icons.location_on_outlined,
                color: Color(0xFF9CA3AF), size: 17),
            const SizedBox(width: 4),
            Text(
              'Deutschland',
              style: GoogleFonts.poppins(color: _kGray, fontSize: 12),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => skillsProv.setQuery(_searchController.text),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Los',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(List<Skill> skills) {
    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(51.1657, 10.4515),
              initialZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.nexus.app',
              ),
              MarkerLayer(markers: _buildMarkers(skills)),
            ],
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${skills.length} SKILLS GELADEN',
                    style: GoogleFonts.poppins(
                      color: _kDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedSkill != null) _buildSkillPopup(_selectedSkill!),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(List<Skill> skills) {
    return skills
        .map((skill) => Marker(
              point: LatLng(skill.lat, skill.lng),
              width: 36,
              height: 36,
              child: GestureDetector(
                onTap: () => setState(() => _selectedSkill = skill),
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBlue,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _kBlue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bolt, color: Colors.white, size: 18),
                ),
              ),
            ))
        .toList();
  }

  Widget _buildFeatures() {
    final features = [
      (
        '📍',
        const Color(0xFFEDE9FE),
        'LOKAL & LIVE',
        'Finde Menschen in deinem direkten Umkreis. Der Radar zeigt dir in Echtzeit an, wer gerade aktiv ist.',
      ),
      (
        '🛡️',
        const Color(0xFFDBEAFE),
        'SICHERE BASIS',
        'Verifizierte Profile und echte Bewertungen. Du entscheidest, wem du deine Skills anbietest.',
      ),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: features
            .map((f) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: f.$2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(f.$1,
                                style: const TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          f.$3,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: _kDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          f.$4,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: _kGray,
                            fontSize: 11,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildWallOfLove() {
    final testimonials = [
      (
        '"Hab jemanden gefunden, der mein Fahrrad repariert hat. Dafür hab ich ihm eine Stunde Spanisch beigebracht. Geniales Konzept!"',
        'SARAH L., BERLIN',
      ),
      (
        '"Der Radar ist super flüssig. Ich biete PC-Hilfe an und habe schon mein halbes Wohnzimmer tapeziert bekommen im Tausch."',
        'THOMAS K., MÜNCHEN',
      ),
    ];

    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
      child: Column(
        children: [
          Text(
            'WALL OF LOVE',
            style: GoogleFonts.poppins(
              color: const Color(0xFFCBD5E1),
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: testimonials
                .map((t) => Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                5,
                                (_) => const Text('★',
                                    style: TextStyle(
                                        color: Color(0xFFF59E0B),
                                        fontSize: 14)),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              t.$1,
                              style: GoogleFonts.poppins(
                                color: _kDark,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '— ${t.$2}',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillPopup(Skill skill) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _kBlue.withOpacity(0.1),
                  backgroundImage: skill.avatarUrl != null
                      ? NetworkImage(skill.avatarUrl!)
                      : null,
                  child: skill.avatarUrl == null
                      ? Text(
                          skill.userName?.substring(0, 1).toUpperCase() ?? '?',
                          style: GoogleFonts.poppins(
                              color: _kBlue, fontWeight: FontWeight.w700))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.skillTitle,
                        style: GoogleFonts.poppins(
                            color: _kDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                      Text(
                        skill.userName ?? '',
                        style: GoogleFonts.poppins(
                            color: _kGray, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _selectedSkill = null),
                  child: const Icon(Icons.close,
                      color: Color(0xFF9CA3AF), size: 17),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              skill.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  GoogleFonts.poppins(color: _kGray, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _openAuth(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _kBlue,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'Anmelden zum Kontaktieren',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openAuth(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}
