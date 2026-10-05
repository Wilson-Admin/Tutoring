import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../資料結構/Structures.dart';

class AuthService {
  static const String baseUrl = 'https://wilson-edu.com';

  /// WebApi 通用共用金鑰 (Bearer Token)
  static const String commonToken =
      'a8Kx#P2mQ9!zL4vN7@cR1tY5*uH3jW0sD6fG9%qE2pX8^nB4kM1+Zr7=Cv5Jt0?yU3iO6lA9F2xH8';

  /// 統一自動產生帶有 Authorization Token 的 Headers
  static Map<String, String> _buildHeaders({
    String? xApiKey,
    String? xUserNo,
    String? xRoleCode,
  }) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $commonToken', // 所有 API 自動固定帶入共用金鑰
      if (xApiKey != null && xApiKey.isNotEmpty) 'X-API-Key': xApiKey,
      if (xUserNo != null && xUserNo.isNotEmpty) 'X-User-No': xUserNo,
      if (xRoleCode != null && xRoleCode.isNotEmpty) 'X-Role-Code': xRoleCode,
    };
  }

  /// 不限長度的 Debug Log 方法
  static void _log(String message, {String tag = 'API LOG'}) {
    if (!kDebugMode) return;

    developer.log(message, name: tag);

    const int chunkSize = 800;
    if (message.length <= chunkSize) {
      debugPrint('[$tag] $message');
    } else {
      debugPrint('[$tag] --- START (Length: ${message.length}) ---');
      for (int i = 0; i < message.length; i += chunkSize) {
        final end = (i + chunkSize < message.length) ? i + chunkSize : message.length;
        debugPrint(message.substring(i, end));
      }
      debugPrint('[$tag] --- END ---');
    }
  }

  /// 登入 API（真實發送 HTTP 請求並接收後端回應）
  static Future<LoginResponse> login({
    required String userNo,
    required String password,
  }) async {
    final url = '$baseUrl/api/tutoring/users/login';
    final headers = _buildHeaders(); // 自動組裝含 Token 之 Headers
    final requestBody = {
      'userNo': userNo,
      'password': password,
    };

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 登入 ======\n'
        'URL: $url\n'
        'Method: POST\n'
        'Headers:\n${encoder.convert(headers)}\n'
        'Body:\n${encoder.convert(requestBody)}');

    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 登入 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      if (decoded is Map<String, dynamic>) {
        return LoginResponse.fromJson(decoded);
      } else {
        return LoginResponse(
          success: false,
          msg: '伺服器回傳格式不正確',
          data: null,
        );
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 登入發生異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return LoginResponse(
        success: false,
        msg: '網路連線失敗，請檢查網路狀態或伺服器連線。',
        data: null,
      );
    }
  }

  /// 變更密碼 API（自動帶入 Token）
  static Future<Map<String, dynamic>> changePassword({
    required String userNo,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/users/change-password';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    ); // 自動封裝 Bearer Token 與自訂 Header
    final requestBody = {
      'userNo': userNo,
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 變更密碼 ======\n'
        'URL: $url\n'
        'Method: POST\n'
        'Headers:\n${encoder.convert(headers)}\n'
        'Body:\n${encoder.convert(requestBody)}');

    try {
      final response = await http
          .post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 變更密碼 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {
          "success": false,
          "msg": "伺服器回傳格式不正確",
          "data": null,
        };
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 變更密碼發生異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {
        "success": false,
        "msg": "網路連線失敗，請檢查網路狀態或稍後再試。",
        "data": null,
      };
    }
  }

  /// 新增 / 更新大頭照 API (規則: U{USER_NO}_{yyyyMMddHHmmssfff}.{ext})
  static Future<Map<String, dynamic>> uploadPhoto({
    required String filePath,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/tutoring/users/photo');
    final request = http.MultipartRequest('POST', url);

    // 設定 Headers
    request.headers.addAll({
      'Authorization': 'Bearer $commonToken',
      'X-API-Key': xApiKey,
      'X-User-No': userNo,
      'X-Role-Code': roleCode,
    });

    // 取得副檔名（預設為 jpg）
    String ext = 'jpg';
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < filePath.length - 1) {
      ext = filePath.substring(dotIndex + 1).toLowerCase();
    }

    // 格式化時間戳：yyyyMMddHHmmssfff (包含 3 位毫秒)
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final MM = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final HH = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final fff = now.millisecond.toString().padLeft(3, '0');
    final timestamp = '$yyyy$MM$dd$HH$mm$ss$fff';

    // 檔名規則：U{USER_NO}_{yyyyMMddHHmmssfff}.{ext}
    final targetFilename = 'U${userNo}_$timestamp.$ext';
    final mimeType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');

    // 加入檔案並指定自訂 filename
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: targetFilename,
        contentType: mimeType,
      ),
    );

    _log('====== [HTTP REQUEST] 上傳大頭照 ======\n'
        'URL: $url\n'
        'Headers: ${request.headers}\n'
        'FilePath: $filePath\n'
        'Generated Filename: $targetFilename');

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      _log('====== [HTTP RESPONSE] 上傳大頭照 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body: $decoded');

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'msg': '回傳格式異常'};
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 上傳大頭照失敗 ======\nError: $e\n$stack');
      return {'success': false, 'msg': '上傳失敗，請檢查網路連線'};
    }
  }
}