class AdminCredentials {
  const AdminCredentials._();

  static const String email = 'admin@planmytripai.com';
  static const String safeCode = '824615';

  static bool isAdminEmail(String? value) {
    return value?.trim().toLowerCase() == email;
  }
}
