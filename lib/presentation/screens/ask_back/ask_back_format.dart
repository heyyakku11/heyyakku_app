/// Short, locale-free time labels for the Ask Back screens.
abstract final class AskBackFormat {
  static const List<String> _months = [
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

  static String _clock(DateTime local) {
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  /// "3:05 PM" today, "Yesterday 3:05 PM", or "12 Oct 3:05 PM".
  static String messageTime(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final today = now ?? DateTime.now();
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;
    if (days <= 0) return _clock(local);
    if (days == 1) return 'Yesterday ${_clock(local)}';
    return '${local.day} ${_months[local.month - 1]} ${_clock(local)}';
  }

  /// How long ago: "just now", "5m ago", "2h ago", "3d ago", then "12 Oct".
  static String relative(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final current = now ?? DateTime.now();
    final elapsed = current.difference(local);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h ago';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d ago';
    return '${local.day} ${_months[local.month - 1]}';
  }

  /// For the conversation list: "3:05 PM", "Yesterday", or "12 Oct".
  static String listTime(DateTime time, {DateTime? now}) {
    final local = time.toLocal();
    final today = now ?? DateTime.now();
    final days = DateTime(
      today.year,
      today.month,
      today.day,
    ).difference(DateTime(local.year, local.month, local.day)).inDays;
    if (days <= 0) return _clock(local);
    if (days == 1) return 'Yesterday';
    return '${local.day} ${_months[local.month - 1]}';
  }
}
