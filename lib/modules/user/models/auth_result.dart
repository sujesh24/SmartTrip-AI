class AuthResult {
  const AuthResult({required this.isSuccess, this.message});

  final bool isSuccess;
  final String? message;

  static const AuthResult success = AuthResult(isSuccess: true);

  factory AuthResult.failure(String message) {
    return AuthResult(isSuccess: false, message: message);
  }
}
