String compactNumber(int value) {
  if (value >= 1000000) {
    final formatted = (value / 1000000).toStringAsFixed(1);
    return '${formatted.replaceAll('.0', '')}M';
  }
  if (value >= 1000) {
    final formatted = (value / 1000).toStringAsFixed(1);
    return '${formatted.replaceAll('.0', '')}K';
  }
  return '$value';
}
