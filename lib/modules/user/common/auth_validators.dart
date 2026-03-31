String? validateEmail(String email) {
  final String normalized = email.trim();
  if (normalized.isEmpty) {
    return 'Email is required.';
  }

  final RegExp emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  if (!emailPattern.hasMatch(normalized)) {
    return 'Please enter a valid email.';
  }

  return null;
}

String? validatePassword(String password) {
  if (password.isEmpty) {
    return 'Password is required.';
  }
  if (password.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  return null;
}
