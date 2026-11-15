import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/text_utils.dart';
import '../../models/category.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skills_provider.dart';
import '../../services/geocoding_service.dart';
import '../../services/location_service.dart';
import '../../widgets/feedback.dart';
import '../../widgets/segmented_choice.dart';
import '../../widgets/skill_type_style.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key, this.initialType = SkillType.offering});

  final SkillType initialType;

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _tags = TextEditingController();

  late SkillType _type = widget.initialType;
  SkillCategory? _category;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _saving = false;
  String? _error;

  bool get _isSearch => _type == SkillType.searching;

  @override
  void initState() {
    super.initState();
    final home = context.read<ProfileProvider>().profile;
    if (home != null && home.hasHome) {
      _lat = home.homeLat;
      _lng = home.homeLng;
      _location.text = home.homeAddress ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<CategoryProvider>().load(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final pos = await LocationService.current();
      final address = await GeocodingService.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        if (address != null) {
          _location.text = address.split(',').take(2).join(',').trim();
        }
      });
    } on LocationUnavailable catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Standort konnte nicht ermittelt werden.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _lookupAddress() async {
    final query = _location.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _locating = true;
      _error = null;
    });
    final hit = await GeocodingService.geocode(query);
    if (!mounted) return;
    setState(() {
      _locating = false;
      if (hit == null) {
        _error = 'Adresse konnte nicht gefunden werden.';
      } else {
        _lat = hit.lat;
        _lng = hit.lng;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().userId;
    final missing = switch ((_category, _lat)) {
      (null, _) => 'Bitte wähle eine Kategorie aus.',
      (_, null) => 'Bitte gib einen Standort an.',
      _ => null,
    };
    if (missing != null || userId == null) {
      setState(() => _error = missing);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final err = await context.read<SkillsProvider>().add(
          Skill(
            id: '',
            userId: userId,
            title: _title.text.trim(),
            description: _description.text.trim(),
            lat: _lat!,
            lng: _lng!,
            type: _type,
            tags: parseTags(_tags.text),
            categoryId: _category!.id,
          ),
        );

    if (!mounted) return;
    if (err == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _saving = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final accent = _type.color;

    return Scaffold(
      appBar: AppBar(title: Text(_isSearch ? 'Skill suchen' : 'Skill anbieten')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SegmentedChoice<SkillType>(
                selected: _type,
                onChanged: (t) => setState(() => _type = t),
                options: const [
                  ChoiceOption(
                    value: SkillType.offering,
                    label: 'Anbieten',
                    icon: Icons.bolt,
                  ),
                  ChoiceOption(
                    value: SkillType.searching,
                    label: 'Suchen',
                    icon: Icons.search_rounded,
                    color: kError,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _Section(
                _isSearch ? 'Was suchst du?' : 'Was bietest du an?',
                icon: _type.icon,
                color: accent,
              ),
              TextFormField(
                controller: _title,
                maxLength: SkillsProvider.maxTitleLength,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Titel',
                  hintText: _isSearch
                      ? 'z. B. Hilfe bei Fahrrad-Reparatur'
                      : 'z. B. Gitarrenunterricht für Anfänger',
                ),
                validator: (v) =>
                    (v?.trim().isEmpty ?? true) ? 'Bitte einen Titel eingeben' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                maxLength: SkillsProvider.maxDescriptionLength,
                decoration: InputDecoration(
                  labelText: 'Beschreibung',
                  alignLabelWithHint: true,
                  hintText: _isSearch
                      ? 'Was brauchst du genau und wie stellst du dir die Hilfe vor?'
                      : 'Was kannst du, wie viel Erfahrung hast du, was bietest du an?',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Bitte eine Beschreibung eingeben'
                    : null,
              ),
              const SizedBox(height: 16),
              _Section('Kategorie', icon: Icons.category_outlined, color: accent),
              if (categories.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in categories)
                      PillChip(
                        label: c.name,
                        emoji: c.icon,
                        color: accent,
                        selected: _category?.id == c.id,
                        onTap: () => setState(() => _category = c),
                      ),
                  ],
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tags,
                maxLength: 300,
                decoration: const InputDecoration(
                  counterText: '',
                  labelText: 'Tags (kommagetrennt)',
                  hintText: 'Musik, Anfänger, Online',
                  prefixIcon: Icon(Icons.tag, color: kTextMuted, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              _Section('Standort', icon: Icons.location_on_outlined, color: accent),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _location,
                      maxLength: 200,
                      onChanged: (_) {
                        if (_lat != null) setState(() => _lat = _lng = null);
                      },
                      onFieldSubmitted: (_) => _lookupAddress(),
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: 'Adresse oder Ort',
                        hintText: 'z. B. München, Schwabing',
                        suffixIcon: IconButton(
                          tooltip: 'Adresse suchen',
                          icon: const Icon(Icons.search, color: kPrimary),
                          onPressed: _locating ? null : _lookupAddress,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _locating ? null : _useCurrentLocation,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: _locating
                          ? const ButtonSpinner()
                          : const Icon(Icons.my_location, size: 20),
                    ),
                  ),
                ],
              ),
              if (_lat != null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: kSuccess, size: 14),
                      SizedBox(width: 6),
                      Text(
                        'Standort gesetzt (wird auf ~100 m gerundet)',
                        style: TextStyle(color: kSuccess, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ErrorBanner(_error!),
              ],
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                icon: _saving
                    ? const ButtonSpinner()
                    : Icon(_isSearch ? Icons.campaign_outlined : Icons.publish, size: 18),
                label: Text(_isSearch ? 'Gesuch veröffentlichen' : 'Skill veröffentlichen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.icon, required this.color});

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
