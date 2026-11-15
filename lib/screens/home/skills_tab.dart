import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/skill.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/skills_provider.dart';
import '../../widgets/feedback.dart';
import '../../widgets/segmented_choice.dart';
import '../../widgets/skill_card.dart';
import '../skills/skill_actions.dart';

class SkillsTab extends StatelessWidget {
  const SkillsTab({super.key, this.origin});

  final LatLng? origin;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SkillsProvider>();
    final categories = context.watch<CategoryProvider>().categories;
    final me = context.select<AuthProvider, String?>((a) => a.userId);
    final skills = provider.filtered(origin: origin);

    return RefreshIndicator(
      onRefresh: () => provider.load(silent: true),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('Skills entdecken'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  onChanged: provider.setQuery,
                  style: const TextStyle(fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Skills suchen …',
                    prefixIcon: Icon(Icons.search, color: kTextMuted, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SegmentedChoice<SkillType?>(
                selected: provider.type,
                onChanged: provider.setType,
                options: const [
                  ChoiceOption(
                    value: null,
                    label: 'Alle',
                    icon: Icons.grid_view_rounded,
                  ),
                  ChoiceOption(
                    value: SkillType.offering,
                    label: 'Angebote',
                    icon: Icons.bolt,
                  ),
                  ChoiceOption(
                    value: SkillType.searching,
                    label: 'Gesuche',
                    icon: Icons.search_rounded,
                    color: kError,
                  ),
                ],
              ),
            ),
          ),
          if (categories.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    PillChip(
                      label: 'Alle',
                      selected: provider.categoryId == null,
                      onTap: () => provider.setCategory(null),
                    ),
                    for (final c in categories)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: PillChip(
                          label: c.name,
                          emoji: c.icon,
                          selected: provider.categoryId == c.id,
                          onTap: () => provider.setCategory(c.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ..._content(provider, skills, me),
        ],
      ),
    );
  }

  List<Widget> _content(
    SkillsProvider provider,
    List<Skill> skills,
    String? me,
  ) {
    if (provider.loading && provider.all.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (provider.error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.cloud_off_rounded,
            title: 'Fehler beim Laden',
            message: provider.error,
            action: ElevatedButton.icon(
              onPressed: provider.load,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Erneut versuchen'),
            ),
          ),
        ),
      ];
    }

    if (skills.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'Keine Skills gefunden',
            message: 'Versuch es mit einem anderen Suchbegriff oder '
                'vergrößere den Radius auf dem Radar.',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        sliver: SliverList.builder(
          itemCount: skills.length,
          itemBuilder: (_, i) {
            final skill = skills[i];
            return SkillCard(
              key: ValueKey(skill.id),
              skill: skill,
              footer: skill.userId == me ? null : SkillActionBar(skill: skill),
            );
          },
        ),
      ),
    ];
  }
}
