String timeAgo(DateTime dateTime, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(dateTime);

  if (difference.inSeconds < 45) return 'just now';
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 24) return '${difference.inHours}h ago';
  if (difference.inDays < 7) return '${difference.inDays}d ago';
  final weeks = (difference.inDays / 7).floor();
  if (weeks < 5) return '${weeks}w ago';
  return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
}
