import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/skill.dart';

extension SkillTypeStyle on SkillType {
  Color get color => this == SkillType.searching ? kError : kPrimary;

  IconData get icon =>
      this == SkillType.searching ? Icons.search_rounded : Icons.bolt;

  String get badge => this == SkillType.searching ? 'Suche' : 'Angebot';
}
