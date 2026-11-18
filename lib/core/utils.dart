import 'package:flutter/widgets.dart';

String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 45) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays == 1) return 'Yesterday';
  return '${d.inDays}d ago';
}

String clockTime(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
}

String percent(double v) => '${(v * 100).round()}%';

/// Global center of the widget that owns [key]; falls back to screen center.
Offset centerOf(GlobalKey key, BuildContext fallback) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    return box.localToGlobal(box.size.center(Offset.zero));
  }
  final size = MediaQuery.sizeOf(fallback);
  return size.center(Offset.zero);
}

String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
