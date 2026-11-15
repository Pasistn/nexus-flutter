import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../models/profile.dart';
import '../../models/rating.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/skills_provider.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/feedback.dart';
import '../../widgets/review_card.dart';
import '../../widgets/skill_type_style.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/user_avatar.dart';
import '../legal/privacy_policy_screen.dart';
import 'all_reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _address = TextEditingController();

  bool _editing = false;
  bool _busy = false;
  String? _error;
  XFile? _newAvatar;
  Uint8List? _newAvatarBytes;
  GeocodingResult? _newHome;
  String? _ratingsRequestedFor;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _address.dispose();
    super.dispose();
  }

  void _startEditing(Profile profile) {
    _name.text = profile.userName ?? '';
    _bio.text = profile.bio ?? '';
    _address.text = profile.homeAddress ?? '';
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _error = null;
      _newAvatar = null;
      _newAvatarBytes = null;
      _newHome = null;
    });
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _newAvatar = file;
      _newAvatarBytes = bytes;
    });
  }

  Future<void> _lookupAddress() async {
    final query = _address.text.trim();
    if (query.isEmpty) return;
    final hit = await GeocodingService.geocode(query);
    if (!mounted) return;
    setState(() {
      _newHome = hit;
      _error = hit == null ? 'Adresse wurde nicht gefunden.' : null;
      if (hit != null) _address.text = hit.displayName;
    });
  }

  Future<void> _save(Profile current) async {
    setState(() {
      _busy = true;
      _error = null;
    });

    final address = nullIfBlank(_address.text);
    final draft = Profile(
      id: current.id,
      userName: nullIfBlank(_name.text),
      bio: nullIfBlank(_bio.text),
      avatarUrl: current.avatarUrl,
      homeAddress: address,
      homeLat: address == null ? null : _newHome?.lat ?? current.homeLat,
      homeLng: address == null ? null : _newHome?.lng ?? current.homeLng,
    );

    final err = await context
        .read<ProfileProvider>()
        .save(draft, avatar: _newAvatar);
    if (!mounted) return;

    setState(() => _busy = false);
    if (err != null) {
      setState(() => _error = err);
    } else {
      _cancelEditing();
      context.read<SkillsProvider>().load(silent: true);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konto löschen?'),
        content: const Text(
          'Dein Profil, deine Skills, Chats und Bewertungen werden '
          'dauerhaft gelöscht. Das lässt sich nicht rückgängig machen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kError),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Endgültig löschen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final err = await context.read<AuthProvider>().deleteAccount();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err != null) _error = 'Löschen fehlgeschlagen: $err';
    });
  }

  Future<void> _deleteSkill(Skill skill) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eintrag löschen?'),
        content: Text('„${skill.title}“ wird entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kError),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final err = await context.read<SkillsProvider>().remove(skill.id);
    if (mounted && err != null) showSnack(context, err, error: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil')),
        body: provider.loading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Icons.person_off_outlined,
                title: 'Profil nicht geladen',
                message: provider.error,
              ),
      );
    }

    if (_ratingsRequestedFor != profile.id) {
      _ratingsRequestedFor = profile.id;
      context.read<RatingsProvider>().ensureLoaded(profile.id);
    }
    final summary = context.watch<RatingsProvider>().summaryFor(profile.id);
    final mySkills = context.watch<SkillsProvider>().ownedBy(profile.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_editing)
            TextButton(onPressed: _cancelEditing, child: const Text('Abbrechen'))
          else
            IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _startEditing(profile),
            ),
          IconButton(
            tooltip: 'Abmelden',
            icon: const Icon(Icons.logout),
            onPressed: context.read<AuthProvider>().signOut,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(profile),
          const SizedBox(height: 24),
          if (_editing) _form(profile) else _info(profile),
          if (_error != null) ...[
            const SizedBox(height: 12),
            ErrorBanner(_error!),
          ],
          const SizedBox(height: 28),
          if (summary != null) _RatingsSection(profile: profile, summary: summary),
          if (mySkills.isNotEmpty) ...[
            const SizedBox(height: 28),
            _OwnSkills(skills: mySkills, onDelete: _deleteSkill),
          ],
          const SizedBox(height: 28),
          const Divider(),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
            icon: const Icon(Icons.privacy_tip_outlined, size: 16, color: kTextMuted),
            label: const Text(
              'Datenschutzerklärung',
              style: TextStyle(color: kTextMuted, fontSize: 13),
            ),
          ),
          TextButton.icon(
            onPressed: _busy ? null : _deleteAccount,
            icon: const Icon(Icons.delete_forever_outlined, size: 16, color: kError),
            label: const Text(
              'Konto löschen',
              style: TextStyle(color: kError, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(Profile profile) {
    final preview = _newAvatarBytes;

    return Column(
      children: [
        Stack(
          children: [
            UserAvatar(
              url: profile.avatarUrl,
              name: profile.userName,
              radius: 52,
              image: preview == null ? null : MemoryImage(preview),
            ),
            if (_editing)
              Positioned(
                right: 0,
                bottom: 0,
                child: IconButton.filled(
                  onPressed: _pickAvatar,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: kPrimary,
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile.userName ?? 'Noch kein Name',
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (profile.bio?.isNotEmpty ?? false)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 14, height: 1.4),
            ),
          ),
      ],
    );
  }

  Widget _info(Profile profile) {
    Widget row(IconData icon, String label, String? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: kTextMuted, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(color: kTextMuted, fontSize: 11)),
                    Text(
                      value ?? '—',
                      style: const TextStyle(color: kTextPrimary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            row(Icons.person_outline, 'Name', profile.userName),
            const Divider(),
            row(Icons.notes_outlined, 'Über mich', profile.bio),
            const Divider(),
            row(Icons.home_outlined, 'Heimatort (Radar-Zentrum)', profile.homeAddress),
          ],
        ),
      ),
    );
  }

  Widget _form(Profile profile) {
    return Column(
      children: [
        TextField(
          controller: _name,
          maxLength: ProfileProvider.maxNameLength,
          decoration: const InputDecoration(
            counterText: '',
            labelText: 'Anzeigename',
            prefixIcon: Icon(Icons.person_outline, color: kTextMuted, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _bio,
          minLines: 2,
          maxLines: 4,
          maxLength: ProfileProvider.maxBioLength,
          decoration: const InputDecoration(
            labelText: 'Über mich',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _address,
          maxLength: ProfileProvider.maxAddressLength,
          onSubmitted: (_) => _lookupAddress(),
          decoration: InputDecoration(
            counterText: '',
            labelText: 'Heimatort / Radar-Zentrum',
            helperText: 'Nur für dich sichtbar',
            prefixIcon: const Icon(Icons.home_outlined, color: kTextMuted, size: 20),
            suffixIcon: IconButton(
              tooltip: 'Adresse suchen',
              icon: const Icon(Icons.search, color: kPrimary),
              onPressed: _lookupAddress,
            ),
          ),
        ),
        if (_newHome != null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: kSuccess, size: 14),
                SizedBox(width: 6),
                Text(
                  'Adresse gefunden',
                  style: TextStyle(color: kSuccess, fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _busy ? null : () => _save(profile),
            child: _busy ? const ButtonSpinner() : const Text('Speichern'),
          ),
        ),
      ],
    );
  }
}

class _RatingsSection extends StatefulWidget {
  const _RatingsSection({required this.profile, required this.summary});

  final Profile profile;
  final RatingSummary summary;

  @override
  State<_RatingsSection> createState() => _RatingsSectionState();
}

class _RatingsSectionState extends State<_RatingsSection> {
  final _pages = PageController(viewportFraction: 0.9);
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    final latest = summary.reviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Bewertungen',
              style: TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            if (summary.count > 0)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AllReviewsScreen(
                      userId: widget.profile.id,
                      userName: widget.profile.userName ?? '',
                    ),
                  ),
                ),
                child: const Text('Alle anzeigen'),
              ),
          ],
        ),
        RatingSummaryLine(average: summary.average, count: summary.count, size: 14),
        const SizedBox(height: 12),
        if (latest.isEmpty)
          const Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'Noch keine Bewertungen erhalten.',
                  style: TextStyle(color: kTextMuted, fontSize: 13),
                ),
              ),
            ),
          )
        else ...[
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _pages,
              padEnds: false,
              itemCount: latest.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ReviewCard(review: latest[i], compact: true),
              ),
            ),
          ),
          if (latest.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < latest.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _page ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _page ? kPrimary : kBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

class _OwnSkills extends StatelessWidget {
  const _OwnSkills({required this.skills, required this.onDelete});

  final List<Skill> skills;
  final ValueChanged<Skill> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meine Einträge (${skills.length})',
          style: const TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        for (final s in skills)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(s.type.icon, color: s.type.color),
              title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                s.categoryName ?? s.type.badge,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: IconButton(
                tooltip: 'Löschen',
                icon: const Icon(Icons.delete_outline, color: kTextMuted),
                onPressed: () => onDelete(s),
              ),
            ),
          ),
      ],
    );
  }
}
