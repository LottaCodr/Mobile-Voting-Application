import 'package:flutter/material.dart';

const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String formatDate(DateTime date) => '${_months[date.month - 1]} ${date.day}, ${date.year}';

String formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final period = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');
  return '${formatDate(date)} · $hour:$minute $period';
}

String formatCompactNumber(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

String countdownLabel(DateTime end, {DateTime? now}) {
  final remaining = end.difference(now ?? DateTime.now());
  if (remaining.isNegative) return 'Closed';
  if (remaining.inDays > 0) return '${remaining.inDays}d left';
  if (remaining.inHours > 0) return '${remaining.inHours}h left';
  if (remaining.inMinutes > 0) return '${remaining.inMinutes}m left';
  return 'Closing now';
}

Color colorFromHex(String hex, {Color fallback = const Color(0xFF1D5FD0)}) {
  final value = hex.replaceAll('#', '').trim();
  if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return fallback;
  return Color(int.parse('FF$value', radix: 16));
}

Color readableOn(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF102A43);
}
