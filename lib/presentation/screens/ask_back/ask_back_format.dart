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
