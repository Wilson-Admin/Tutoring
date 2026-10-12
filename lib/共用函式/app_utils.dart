import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../登入/LoginPage.dart';
import 'app_dialog.dart';

/// 判斷當前裝置是否為平板（最短邊 >= 600 視為平板）
bool get isTablet {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final data = MediaQueryData.fromView(view);
  return data.size.shortestSide >= 600;
}


/// 強制登出並導向登入頁面
/// 強制登出並導向登入頁面
Future<void> forceLogout([BuildContext? context, String message = 'X-API-Key 驗證失敗或已過期。']) async {
  final targetContext = context ?? navigatorKey.currentContext;
  if (targetContext == null) return;

  await AppDialog.show(
    title: '上傳失敗',
    message: message,
    confirmText: '確定',
    onConfirm: () async {
      final prefs = await SharedPreferences.getInstance();

      final isRemembered = prefs.getBool('saved_remember_me') ?? false;
      final savedPhone = prefs.getString('saved_user_phone');
      final savedPassword = prefs.getString('saved_user_password');

      // 清除目前使用者的 Token 與登入狀態
      await prefs.remove('token');
      await prefs.remove('user_token');
      await prefs.remove('x_api_key');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('is_logged_in');

      // 若有記住帳密則保留
      if (isRemembered && savedPhone != null) {
        await prefs.setBool('saved_remember_me', true);
        await prefs.setString('saved_user_phone', savedPhone);
        if (savedPassword != null) {
          await prefs.setString('saved_user_password', savedPassword);
        }
      }

      final activeContext = context ?? navigatorKey.currentContext;
      if (activeContext == null || !activeContext.mounted) return;

      Navigator.of(activeContext, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );

      RestartWidget.restartApp(activeContext);
    },
  );
}