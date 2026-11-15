String _two(int n) => n.toString().padLeft(2, '0');

String formatDate(DateTime dt) {
  final d = dt.toLocal();
  return '${d.day}.${d.month}.${d.year}';
}

String formatClock(DateTime dt) {
  final d = dt.toLocal();
  return '${_two(d.hour)}:${_two(d.minute)}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatChatListTime(DateTime dt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = dt.toLocal();
  final diff = current.difference(local);

  if (diff.inMinutes < 1) return 'Jetzt';
  if (diff.inHours < 1) return '${diff.inMinutes} min';
  if (_sameDay(local, current)) return formatClock(local);
  if (_sameDay(local, current.subtract(const Duration(days: 1)))) {
    return 'Gestern';
  }
  return '${local.day}.${local.month}.';
}

String formatMessageTime(DateTime dt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final local = dt.toLocal();

  if (_sameDay(local, current)) return formatClock(local);
  if (_sameDay(local, current.subtract(const Duration(days: 1)))) {
    return 'Gestern, ${formatClock(local)}';
  }
  return '${formatDate(local)}, ${formatClock(local)}';
}
