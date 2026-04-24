String formatHomeUsername(String? email) {
  final String trimmedEmail = (email ?? '').trim();
  if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
    return 'Guest';
  }

  String localPart = trimmedEmail.split('@').first.trim();
  if (localPart.isEmpty) {
    return 'Guest';
  }

  localPart = localPart.replaceAll(RegExp(r'[._\-]+'), ' ').trim();
  if (localPart.isEmpty) {
    return 'Guest';
  }

  final List<String> words = localPart.split(RegExp(r'\s+'));
  final String formatted = words
      .where((String word) => word.isNotEmpty)
      .map((String word) {
        final String lower = word.toLowerCase();
        if (lower.length == 1) {
          return lower.toUpperCase();
        }
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');

  return formatted.isEmpty ? 'Guest' : formatted;
}
