import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

class ImageDownloadUtil {

  /// 針對 iPad/iPhone 優化的共用提示訊息 (浮動式、避免遮擋底部 Home 條)
  /// 針對 iPad/iPhone 優化的共用提示訊息
  static void _showToast(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          // 👇 2. 拿掉 const，加上 .sp 讓字體在 iPad 自動放大
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
        // 👇 3. 加上 .h 與 .w 讓邊距跟著螢幕比例走
        margin: EdgeInsets.only(bottom: 30.h, left: 20.w, right: 20.w),
        backgroundColor: isError ? Colors.red.shade600 : const Color(0xFF344054),
        // 👇 4. 加上 .r 讓圓角比例正確
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 共用函式：下載圖片至手機相簿
  static Future<void> saveImageToGallery(BuildContext context, String url) async {
    try {
      _showToast(context, '圖片下載中...');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {

        // 👇 自動判斷副檔名，防止 iOS 的 PNG 或 HEIC 被強轉 JPG 導致損壞
        String ext = 'jpg';
        try {
          final uriPath = Uri.parse(url).path;
          if (uriPath.contains('.')) {
            ext = uriPath.split('.').last.toLowerCase();
          }
        } catch (_) {}
        // 若不是常見圖片格式，給予防呆預設值
        if (!['jpg', 'jpeg', 'png', 'heic', 'heif'].contains(ext)) {
          ext = 'jpg';
        }

        final tempDir = await getTemporaryDirectory();

        // 建立暫存檔案 (動態套用正確的副檔名)
        final file = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.$ext');

        // 寫入完整二進位資料 (完整保留 EXIF 旋轉資訊)
        await file.writeAsBytes(response.bodyBytes);

        // 存入手機相簿
        final result = await ImageGallerySaverPlus.saveFile(file.path);

        final isSuccess = result != null && result['isSuccess'] == true;

        if (isSuccess) {
          _showToast(context, '✅ 圖片已成功儲存至相簿！');
        } else {
          _showToast(context, '❌ 儲存失敗，請檢查相簿權限', isError: true);
        }

        // 存檔完成後刪除暫存檔，釋放空間
        if (await file.exists()) {
          await file.delete();
        }

      } else {
        _showToast(context, '❌ 下載失敗，伺服器無回應', isError: true);
      }
    } catch (e) {
      debugPrint('圖片下載異常: $e');
      _showToast(context, '❌ 圖片下載發生異常', isError: true);
    }
  }
}