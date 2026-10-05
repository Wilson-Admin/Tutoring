import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyPhone = 'saved_user_phone';
  static const String _keyPassword = 'saved_user_password';
  static const String _keyRememberMe = 'saved_remember_me';

  /// 儲存帳密與狀態
  static Future<void> saveCredentials({
    required String phone,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (rememberMe) {
      await prefs.setString(_keyPhone, phone);
      await prefs.setString(_keyPassword, password);
      await prefs.setBool(_keyRememberMe, true);
    } else {
      await clearCredentials();
    }
  }

  /// 讀取儲存的帳密
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final isRemembered = prefs.getBool(_keyRememberMe) ?? false;

    if (isRemembered) {
      final phone = prefs.getString(_keyPhone) ?? '';
      final password = prefs.getString(_keyPassword) ?? '';
      return {
        'rememberMe': true,
        'phone': phone,
        'password': password,
      };
    }

    return {
      'rememberMe': false,
      'phone': '',
      'password': '',
    };
  }

  /// 清除儲存的帳密
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyRememberMe);
  }
}