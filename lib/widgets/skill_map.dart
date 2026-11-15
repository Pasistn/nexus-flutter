import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/theme/app_theme.dart';
import '../models/skill.dart';
import 'skill_type_style.dart';

class SkillMap extends StatelessWidget {
  const SkillMap({
    super.key,
    required this.skills,
    required this.initialCenter,
    this.initialZoom = 12,
    this.controller,
    this.onSkillTap,
    this.home,
  });

  final List<Skill> skills;
  final LatLng initialCenter;
  final double initialZoom;
  final MapController? controller;
  final ValueChanged<Skill>? onSkillTap;
  final LatLng? home;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.nexus.nexus_flutter',
        ),
        MarkerLayer(
          markers: [
            if (home != null)
              Marker(point: home!, width: 40, height: 40, child: const _HomePin()),
            for (final s in skills)
              Marker(
                point: LatLng(s.lat, s.lng),
                width: 42,
                height: 42,
                child: _SkillPin(skill: s, onTap: onSkillTap),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('OpenStreetMap'),
          backgroundColor: Color(0xCCFFFFFF),
        ),
      ],
    );
  }
}

class _SkillPin extends StatelessWidget {
  const _SkillPin({required this.skill, this.onTap});

  final Skill skill;
  final ValueChanged<Skill>? onTap;

  @override
  Widget build(BuildContext context) {
    final color = skill.type.color;
    return GestureDetector(
      onTap: onTap == null ? null : () => onTap!(skill),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(skill.type.icon, color: color, size: 21),
      ),
    );
  }
}

class _HomePin extends StatelessWidget {
  const _HomePin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.45),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
    );
  }
}
