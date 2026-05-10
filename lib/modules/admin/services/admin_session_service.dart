import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:smarttrip_ai/modules/admin/common/admin_constants.dart';

class AdminSessionService {
  AdminSessionService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _verifiedKey = 'admin_verified_session';
  static const String _emailKey = 'admin_verified_email';

  final FlutterSecureStorage _storage;

  Future<bool> hasVerifiedAdminSession(String? email) async {
    if (!AdminCredentials.isAdminEmail(email)) {
      return false;
    }

    final List<String?> values = await Future.wait(<Future<String?>>[
      _storage.read(key: _verifiedKey),
      _storage.read(key: _emailKey),
    ]);

    return values[0] == 'true' && AdminCredentials.isAdminEmail(values[1]);
  }

  Future<void> saveVerifiedAdminSession(String email) async {
    if (!AdminCredentials.isAdminEmail(email)) {
      return;
    }

    await Future.wait(<Future<void>>[
      _storage.write(key: _verifiedKey, value: 'true'),
      _storage.write(key: _emailKey, value: AdminCredentials.email),
    ]);
  }

  Future<void> clearAdminSession() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _verifiedKey),
      _storage.delete(key: _emailKey),
    ]);
  }
}
