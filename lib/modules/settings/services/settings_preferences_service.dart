import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsPreferencesService {
  Future<bool> loadNotificationsEnabled();
  Future<void> saveNotificationsEnabled(bool isEnabled);
}

class SharedPrefsSettingsPreferencesService
    implements SettingsPreferencesService {
  static const String _notificationsEnabledKey =
      'settings.notifications.enabled';

  @override
  Future<bool> loadNotificationsEnabled() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_notificationsEnabledKey) ?? true;
  }

  @override
  Future<void> saveNotificationsEnabled(bool isEnabled) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_notificationsEnabledKey, isEnabled);
  }
}
