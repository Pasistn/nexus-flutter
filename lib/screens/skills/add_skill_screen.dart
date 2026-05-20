import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/category.dart' show SkillCategory;
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skills_provider.dart';
import '../../services/geocoding_service.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  double? _lat, _lng;
  bool _locating = false;
  bool _saving = false;
  String? _error;
  SkillCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      final address = await GeocodingService.reverseGeocode(_lat!, _lng!);
      if (address != null && mounted) {
        setState(() => _locationCtrl.text = address.split(',').take(2).join(', '));
      }
    } catch (e) {
      setState(() => _error = 'Standort konnte nicht ermittelt werden.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _geocodeAddress() async {
    final address = _locationCtrl.text.trim();
    if (address.isEmpty) return;

    setState(() => _locating = true);
    final result = await GeocodingService.geocode(address);
    if (!mounted) return;

    if (result != null) {
      setState(() {
        _lat = result.lat;
        _lng = result.lng;
      });
    } else {
      setState(() => _error = 'Adresse konnte nicht gefunden werden.');
    }
    setState(() => _locating = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _error = 'Bitte wähle eine Kategorie aus.');
      return;
    }
    if (_lat == null || _lng == null) {
      setState(() => _error = 'Bitte gib einen Standort an.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>().profile;

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final skill = Skill(
      id: '',
      userId: auth.currentUser!.id,
      userName: profile?.userName,
      avatarUrl: profile?.avatarUrl,
      skillTitle: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      lat: _lat!,
      lng: _lng!,
      tags: tags,
      categoryId: _selectedCategory!.id,
    );

    final err = await context.read<SkillsProvider>().addSkill(skill);

    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;

    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(title: const Text('Skill anbieten')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Was bietest du an?', Icons.bolt),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Skill-Titel *',
                    hintText: 'z. B. Gitarrenunterricht für Anfänger',
                    prefixIcon: Icon(Icons.title, color: kTextMuted, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Bitte einen Titel eingeben'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung *',
                    hintText:
                        'Beschreibe deine Fähigkeit, Erfahrung und was du anbietest...',
                    prefixIcon: Icon(Icons.description_outlined,
                        color: kTextMuted, size: 20),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Bitte eine Beschreibung eingeben'
                      : null,
                ),
                const SizedBox(height: 14),
                _buildCategoryPicker(categories),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (kommagetrennt)',
                    hintText: 'Musik, Anfänger, Online',
                    prefixIcon: Icon(Icons.tag, color: kTextMuted, size: 20),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Standort', Icons.location_on),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _locationCtrl,
                        decoration: InputDecoration(
                          labelText: 'Adresse / Ort',
                          hintText: 'München, Bayern',
                          prefixIcon: const Icon(Icons.location_on_outlined,
                              color: kTextMuted, size: 20),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search,
                                color: kNeonOrange, size: 20),
                            onPressed: _geocodeAddress,
                          ),
                        ),
                        onFieldSubmitted: (_) => _geocodeAddress(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _locating ? null : _useCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        minimumSize: const Size(50, 50),
                      ),
                      child: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 20),
                    ),
                  ],
                ),
                if (_lat != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: kSuccess, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Koordinaten gesetzt: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                        style: const TextStyle(color: kSuccess, fontSize: 12),
                      ),
                    ],
                  ),
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
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: kError, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(
                                  color: kError, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.black, strokeWidth: 2))
                        : const Icon(Icons.publish, size: 18),
                    label:
                        Text(_saving ? 'Wird veröffentlicht...' : 'Skill veröffentlichen'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryPicker(List<SkillCategory> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_outlined, color: kNeonOrange, size: 18),
            const SizedBox(width: 8),
            const Text('Kategorie *',
                style: TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        if (categories.isEmpty)
          const Center(
              child: CircularProgressIndicator(color: kNeonOrange, strokeWidth: 2))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((SkillCategory cat) {
              final selected = _selectedCategory?.id == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? kNeonOrange.withOpacity(0.15)
                        : kBgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? kNeonOrange : kBorderColor,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat.icon != null) ...[
                        Text(cat.icon!, style: const TextStyle(fontSize: 15)),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        cat.name,
                        style: TextStyle(
                          color: selected ? kNeonOrange : kTextSecondary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: kNeonOrange, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
      ],
    );
  }
}
