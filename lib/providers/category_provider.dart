import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/supabase_constants.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final _client = Supabase.instance.client;
  List<SkillCategory> _categories = [];
  bool _loaded = false;

  List<SkillCategory> get categories => _categories;

  Future<void> loadCategories() async {
    if (_loaded) return;
    try {
      final data = await _client
          .from(SupabaseConstants.categoriesTable)
          .select()
          .order('name');
      _categories =
          (data as List).map((e) => SkillCategory.fromJson(e)).toList();
      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }
}
