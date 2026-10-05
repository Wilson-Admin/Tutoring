import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import '../main.dart'; // 引用 main.dart 的全域 navigatorKey

class AppDialog {
  /// 取得全域 Context（優先使用傳入的 context，若無則使用全域 navigatorKey）
  static BuildContext? get _globalContext =>
      navigatorKey.currentState?.overlay?.context ?? navigatorKey.currentContext;

  /// 全域提示 / 錯誤 Dialog（一律純白底）
  static Future<void> show({
    BuildContext? context,
    String title = '提示',
    required String message,
    String confirmText = '確定',
    VoidCallback? onConfirm,
    bool barrierDismissible = false,
  }) async {
    final ctx = context ?? _globalContext;
    if (ctx == null) return;

    return showDialog<void>(
      context: ctx,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, // 👈 一律純白底色
          surfaceTintColor: Colors.transparent, // 👈 移除 Material 3 自動疊加的灰紫色調
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF616161),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onConfirm != null) onConfirm();
              },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2979FF),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              ),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 全域確認對話框（包含 取消 / 確定 按鈕）
  static Future<bool> showConfirm({
    BuildContext? context,
    String title = '提示',
    required String message,
    String confirmText = '確定',
    String cancelText = '取消',
  }) async {
    final ctx = context ?? _globalContext;
    if (ctx == null) return false;

    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white, // 👈 一律純白底色
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
            ),
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF616161),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF757575),
              ),
              child: Text(cancelText, style: TextStyle(fontSize: 15.sp)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2979FF),
              ),
              child: Text(
                confirmText,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}