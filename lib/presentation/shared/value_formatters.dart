String readable(dynamic value) {
  final words = (value ?? '')
      .toString()
      .replaceAll('_', ' ')
      .trim()
      .split(RegExp(r'\s+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
