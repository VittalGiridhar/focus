String formatCountdown(Duration d) {
  final total = d.isNegative ? 0 : d.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two(total % 3600 ~/ 60)}:${two(total % 60)}';
}

String formatDuration(Duration d) {
  if (d <= Duration.zero) return '0 min';
  if (d < const Duration(minutes: 1)) return '<1 min';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m min';
  if (m == 0) return h == 1 ? '1 hour' : '$h hours';
  return '${h}h ${m}m';
}
