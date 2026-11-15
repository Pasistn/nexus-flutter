import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ratings_provider.dart';
import '../../providers/skills_provider.dart';
import '../../widgets/nexus_logo.dart';
import '../../widgets/skill_map.dart';
import '../../widgets/skill_type_style.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/user_avatar.dart';
import '../skills/skill_actions.dart';

const _munich = LatLng(48.1351, 11.5820);

class RadarTab extends StatefulWidget {
  const RadarTab({super.key, this.origin, this.home});

  final LatLng? origin;
  final LatLng? home;

  @override
  State<RadarTab> createState() => _RadarTabState();
}

class _RadarTabState extends State<RadarTab> {
  final _map = MapController();
  Skill? _selected;

  @override
  void didUpdateWidget(RadarTab old) {
    super.didUpdateWidget(old);
    final target = widget.origin;
    if (target != null && target != old.origin) {
      try {
        _map.move(target, 12);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _select(Skill skill) {
    context.read<RatingsProvider>().ensureLoaded(skill.userId);
    setState(() => _selected = skill);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillsProvider>();
    final skills = provider.filtered(origin: widget.origin, ignoreType: true);

    return Stack(
      children: [
        SkillMap(
          controller: _map,
          skills: skills,
          initialCenter: widget.origin ?? _munich,
          home: widget.home,
          onSkillTap: _select,
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(child: _RadarHeader(count: skills.length)),
        ),
        if (_selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 88,
            child: _SkillPopup(
              skill: _selected!,
              onClose: () => setState(() => _selected = null),
            ),
          ),
      ],
    );
  }
}

class _RadarHeader extends StatelessWidget {
  const _RadarHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillsProvider>();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const NexusLogo(size: 32),
              const SizedBox(width: 8),
              const Text(
                'Nexus Radar',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kSuccess.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '● $count Skills',
                  style: const TextStyle(
                    color: kSuccess,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: provider.setQuery,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              hintText: 'Skills suchen …',
              prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.radar, color: kTextMuted, size: 16),
              const SizedBox(width: 6),
              SizedBox(
                width: 78,
                child: Text(
                  provider.isNationwide
                      ? 'Bundesweit'
                      : '${provider.radiusKm.round()} km',
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Slider(
                  value: provider.radiusKm,
                  min: 1,
                  max: SkillsProvider.maxRadiusKm,
                  onChanged: provider.setRadius,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillPopup extends StatelessWidget {
  const _SkillPopup({required this.skill, required this.onClose});

  final Skill skill;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final summary = context.watch<RatingsProvider>().summaryFor(skill.userId);
    final isMine = context.read<AuthProvider>().userId == skill.userId;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(
          color: kBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: skill.type.color.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar(url: skill.avatarUrl, name: skill.userName),
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
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        skill.userName ?? '',
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (summary != null)
                        RatingSummaryLine(
                          average: summary.average,
                          count: summary.count,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: kTextMuted, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                skill.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            if (!isMine) ...[
              const SizedBox(height: 10),
              SkillActionBar(skill: skill, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}
