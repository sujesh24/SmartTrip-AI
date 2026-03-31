String mapFirebaseAuthErrorCode(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'This email is already registered. Try logging in instead.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'weak-password':
      return 'Password is too weak. Use at least 8 characters.';
    case 'user-not-found':
      return 'No account found with this email.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'too-many-requests':
      return 'Too many attempts. Please try again later.';
    case 'network-request-failed':
      return 'Network error. Check your connection and try again.';
    case 'account-exists-with-different-credential':
      return 'This email is linked with a different sign-in method.';
    case 'user-disabled':
      return 'This account has been disabled.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

String mapGoogleSignInError(Object error) {
  final String normalizedError = error.toString().toLowerCase();

  if (normalizedError.contains('network') ||
      normalizedError.contains('socket') ||
      normalizedError.contains('timed out')) {
    return 'Network error. Check your connection and try again.';
  }

  if (normalizedError.contains('api exception: 10') ||
      normalizedError.contains('developer_error') ||
      normalizedError.contains('12500') ||
      normalizedError.contains('oauth') ||
      normalizedError.contains('sign_in_failed') ||
      normalizedError.contains('configuration')) {
    return 'Google sign-in is not configured for this Android app yet. Add SHA-1/SHA-256 in Firebase, then download and replace google-services.json.';
  }

  return 'Unable to sign in with Google. Please try again.';
}
