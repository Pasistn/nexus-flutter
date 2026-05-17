import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/profile.dart';
import '../../models/rating.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../screens/profile/all_reviews_screen.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/star_rating_bar.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;
  String? _error;
  File? _pendingAvatar;
  double? _pendingLat, _pendingLng;
  String? _loadedForUserId;
  final PageController _reviewPageCtrl = PageController(viewportFraction: 0.88);
  int _reviewPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null && profile.id != _loadedForUserId) {
      _loadedForUserId = profile.id;
      _populateFields(profile);
      context.read<RatingsProvider>().loadForUser(profile.id);
    }
  }

  void _populateFields(Profile profile) {
    _nameCtrl.text = profile.userName ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _addressCtrl.text = profile.homeAddress ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _addressCtrl.dispose();
    _reviewPageCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _pendingAvatar = File(picked.path));
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) return;

    final result = await GeocodingService.geocode(address);
    if (result != null) {
      setState(() {
        _pendingLat = result.lat;
        _pendingLng = result.lng;
        _addressCtrl.text = result.displayName;
      });
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final profileProv = context.read<ProfileProvider>();
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser!.id;
    final existing = profileProv.profile;

    String? avatarUrl = existing?.avatarUrl;
    if (_pendingAvatar != null) {
      avatarUrl = await profileProv.uploadAvatar(userId, _pendingAvatar!);
    }

    final updated = Profile(
      id: userId,
      userName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text.trim(),
      avatarUrl: avatarUrl,
      homeAddress: _addressCtrl.text.trim(),
      homeLat: _pendingLat ?? existing?.homeLat,
      homeLng: _pendingLng ?? existing?.homeLng,
      skillPoints: existing?.skillPoints ?? 0,
    );

    final err = await profileProv.upsertProfile(updated);

    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
      if (err == null) _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profileProv = context.watch<ProfileProvider>();
    final profile = profileProv.profile;
    final ratingSummary = profile != null
        ? context.watch<RatingsProvider>().getSummary(profile.id)
        : null;

    if (!auth.isAuthenticated) {
      return const Center(
        child: Text('Bitte anmelden', style: TextStyle(color: kTextSecondary)),
      );
    }

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                if (profile != null) _populateFields(profile);
                setState(() => _editing = true);
              },
            )
          else
            TextButton(
              onPressed: () => setState(() {
                _editing = false;
                _pendingAvatar = null;
              }),
              child: const Text('Abbrechen'),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              context.read<ProfileProvider>().clear();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildAvatarSection(profile),
            const SizedBox(height: 16),
            if (ratingSummary != null)
              _buildRatingSection(ratingSummary),
            const SizedBox(height: 16),
            if (_editing) ...[
              _buildEditForm(),
            ] else ...[
              _buildInfoCard(profile),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kError.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kError.withOpacity(0.3)),
                ),
                child: Text(_error!,
                    style: const TextStyle(color: kError, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection(Profile? profile) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: kBgCard,
              backgroundImage: _pendingAvatar != null
                  ? FileImage(_pendingAvatar!) as ImageProvider
                  : (profile?.avatarUrl != null
                      ? CachedNetworkImageProvider(profile!.avatarUrl!)
                      : null),
              child:
                  (_pendingAvatar == null && profile?.avatarUrl == null)
                      ? Text(
                          profile?.userName
                                  ?.substring(0, 1)
                                  .toUpperCase() ??
                              '?',
                          style: const TextStyle(
                              color: kNeonOrange,
                              fontSize: 32,
                              fontWeight: FontWeight.w800),
                        )
                      : null,
            ),
            if (_editing)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: kNeonOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: kBgDark, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt,
                        color: Colors.black, size: 16),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          profile?.userName ?? 'Kein Name',
          style: const TextStyle(
              color: kTextPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700),
        ),
        if (profile?.bio?.isNotEmpty ?? false) ...[
          const SizedBox(height: 4),
          Text(profile!.bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 14, height: 1.4)),
        ],
      ],
    );
  }

  Widget _buildRatingSection(RatingSummary summary) {
    final reviews = summary.reviews.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: kNeonOrange, size: 18),
              const SizedBox(width: 6),
              const Text('Bewertungen',
                  style: TextStyle(
                      color: kTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
              const Spacer(),
              if (summary.count > 0)
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllReviewsScreen(
                        userId: context.read<ProfileProvider>().profile!.id,
                        userName: context.read<ProfileProvider>().profile?.userName ?? '',
                      ),
                    ),
                  ),
                  child: const Text('Alle anzeigen',
                      style: TextStyle(color: kNeonOrange, fontSize: 13)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: StarRatingBar(
              rating: summary.avg, count: summary.count, size: 14),
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kBgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorderColor),
            ),
            child: const Center(
              child: Text('Noch keine Bewertungen erhalten.',
                  style: TextStyle(color: kTextMuted, fontSize: 13)),
            ),
          )
        else ...[
          SizedBox(
            height: 150,
            child: PageView.builder(
              controller: _reviewPageCtrl,
              itemCount: reviews.length,
              onPageChanged: (i) => setState(() => _reviewPage = i),
              itemBuilder: (_, i) => _buildReviewCard(reviews[i]),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(reviews.length, (i) {
              final active = i == _reviewPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? kNeonOrange : kTextMuted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewCard(Rating review) {
    final raterName = review.raterName ?? 'Anonym';
    final createdAt = review.createdAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kBgCardElevated,
                  child: Text(
                    raterName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: kNeonOrange,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(raterName,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: i < review.rating ? kNeonOrange : kTextMuted,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                '${createdAt.day}.${createdAt.month}.${createdAt.year}',
                style: const TextStyle(color: kTextMuted, fontSize: 11),
              ),
            ],
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  review.comment!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: kTextSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Profile? profile) {
    if (profile == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profil-Info',
              style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16)),
          const SizedBox(height: 12),
          _infoRow(Icons.person_outline, 'Name',
              profile.userName ?? '—'),
          const Divider(),
          _infoRow(Icons.info_outline, 'Bio', profile.bio ?? '—'),
          const Divider(),
          _infoRow(Icons.location_on_outlined, 'Heimatort',
              profile.homeAddress ?? '—'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
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
                Text(label,
                    style: const TextStyle(color: kTextMuted, fontSize: 11)),
                Text(value,
                    style: const TextStyle(
                        color: kTextPrimary, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEditForm() {
    return Column(
      children: [
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Anzeigename',
            prefixIcon:
                Icon(Icons.person_outline, color: kTextMuted, size: 20),
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _bioCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Über mich',
            prefixIcon: Icon(Icons.info_outline, color: kTextMuted, size: 20),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _addressCtrl,
          decoration: InputDecoration(
            labelText: 'Heimatort / Radar-Zentrum',
            prefixIcon: const Icon(Icons.location_on_outlined,
                color: kTextMuted, size: 20),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: kNeonOrange, size: 20),
              onPressed: _geocodeAddress,
            ),
          ),
          onFieldSubmitted: (_) => _geocodeAddress(),
        ),
        if (_pendingLat != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: kSuccess, size: 14),
              const SizedBox(width: 6),
              Text(
                'Koordinaten: ${_pendingLat!.toStringAsFixed(4)}, ${_pendingLng!.toStringAsFixed(4)}',
                style: const TextStyle(color: kSuccess, fontSize: 12),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.black, strokeWidth: 2))
                : const Text('Änderungen speichern'),
          ),
        ),
      ],
    );
  }
}
