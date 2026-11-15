import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/tables.dart';
import '../core/utils/error_utils.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<SkillCategory> _categories = const [];
  Future<void>? _pending;

  List<SkillCategory> get categories => _categories;

  Future<void> load() {
    if (_categories.isNotEmpty) return Future.value();
    return _pending ??= _fetch().whenComplete(() => _pending = null);
  }

  Future<void> _fetch() async {
    try {
      final rows = await _client.from(Tables.categories).select().order('name');
      _categories = rows.map(SkillCategory.fromJson).toList();
      notifyListeners();
    } catch (e) {
      friendlyError(e);
    }
  }
}
