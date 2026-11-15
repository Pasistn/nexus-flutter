String initialOf(String? name, {String fallback = '?'}) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return fallback;
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}

String escapeLike(String input) => input
    .replaceAll(r'\', r'\\')
    .replaceAll('%', r'\%')
    .replaceAll('_', r'\_');

String? nullIfBlank(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

List<String> parseTags(String raw, {int max = 10, int maxLength = 30}) => raw
    .split(',')
    .map((t) => t.trim())
    .where((t) => t.isNotEmpty && t.length <= maxLength)
    .toSet()
    .take(max)
    .toList();
