import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../共用函式/app_dialog.dart'; // 若 forceLogout 放置的檔案路徑不同請依實際位置調整
import '../共用函式/app_utils.dart';
import '../資料結構/ChatListResponse.dart';
import '../資料結構/Structures.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../資料結構/StudentListResponse.dart';

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

  /// 統一檢查 API 回傳訊息，若為憑證/Key過期或驗證失敗，一律自動登出
  static void _handleAuthExpired(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final msg = decoded['msg']?.toString() ?? '';
      if (msg.contains('X-API-Key 驗證失敗') ||
          msg.contains('已過期') ||
          (msg.contains('X-API-Key') && msg.contains('失敗'))) {
        forceLogout(null, msg);
      }
    }
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

      _handleAuthExpired(decoded);

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

      _handleAuthExpired(decoded);

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

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'msg': '回傳格式異常'};
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 上傳大頭照失敗 ======\nError: $e\n$stack');
      return {'success': false, 'msg': '上傳失敗，請檢查網路連線'};
    }
  }


  /// 刪除大頭照 API
  static Future<Map<String, dynamic>> deletePhoto({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/users/photo';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 刪除大頭照 ======\n'
        'URL: $url\n'
        'Method: DELETE\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .delete(
        Uri.parse(url),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 刪除大頭照 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

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
      _log('====== [HTTP ERROR] 刪除大頭照發生異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {
        "success": false,
        "msg": "網路連線失敗，請檢查網路狀態或稍後再試。",
        "data": null,
      };
    }
  }


  /// 新增 / 更新 FCM Token API
  static Future<Map<String, dynamic>> updateFcmToken({
    required String fcmToken,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/users/fcm';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );
    final requestBody = {
      'fcm': fcmToken,
    };

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 更新 FCM Token ======\n'
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

      _log('====== [HTTP RESPONSE] 更新 FCM Token ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

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
      _log('====== [HTTP ERROR] 更新 FCM Token 異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {
        "success": false,
        "msg": "網路連線失敗，請檢查網路狀態或稍後再試。",
        "data": null,
      };
    }
  }


  /// 直接呼叫 Google FCM HTTP v1 API 發送推播
  /// 直接呼叫 Google FCM HTTP v1 API 發送真實推播至指定手機
  static Future<Map<String, dynamic>> sendGoogleFcmNotification({
    required String fcmToken,
    required String title,
    required String body,
  }) async {
    // 完整帶入 service account json 所有必要欄位（特別是 "type": "service_account"）
    final serviceAccountMap = {
      "type": "service_account",
      "project_id": "tutoring-e52e6",
      "private_key_id": "405da258e0a7a5e57d0975fb054cf4d5551a0182",
      "private_key":
      "-----BEGIN PRIVATE KEY-----\n"
          "MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCxxjPk8lVkBFQ8\n"
          "SM1ZYVpFwgHcfA2yvONN3xVoGOT/+x8J4mNvA6EtU6RpyAQQTh0ZuRaqF5mTeCGx\n"
          "8/89AREynwCEZXR3gcWfVyuay7pYU+Ed0C+XwaaBHRjMRmjZirkQ0Vxhge3Xsi9/\n"
          "YqAsn9UqKH2HjNmFveYoLBuJwLXSQ2eOlI15fLuSUqvaLBdWfceSIX0GUSiQUh5Q\n"
          "FcwBpjv/rfKHoIisUuwHcEQG+Rs+WqNsbDpqD8It6sLL/UJxt6kEwJpspufBUQbN\n"
          "eMvhNesQxrEyh5Q85SIjlBwoc9qB2Ff43hUZaP1Kfbm8gV+usa+iIL4D2QOW+NBA\nXNHrqpaJAgMBAAECggEABlwRUjDrJhtTih6OnhJyAMnaeDFF6i2AsjH3WZR+aLvq\n"
          "lddv+DI4i18RJCmgH5czyk5JRcd3WoOzLOMOL/gATf/LLHFWs8nEMJmVOUHthihm\n"
          "BsOCWFr4omjQkMo6CQJB8ZyTwfc8c3lv4o48LayAGzR8nSNIStUKzUgaqhhnSMDK\n"
          "SaRsK9AbKyI1a+62Y6WLDRePBkvncqdDCGSJAdALh0vbrqcvG7fZM5B2n8CJ7Rf2\nxD38aHdk7BlHub1NLRwBhe6FB33sf9QVINojK4WKNQKDE+kITmVpsprZUuS2Ffn4\n"
          "L3vzbjXGu7CyvWg/jJnoK/occ/tg72cC1CtGoatfiQKBgQDVjjPZxJLD1huknDYx\n"
          "6U4z+w07pO0mvZ5LDPSrOSmAoZv1JD/tWtlJBNWx5E8w5G0XByR1MK4doCMGfWRj\n"
          "blkNbp0VV/Z+oQveIcyWYRiCjf9ZHeFYw6Q+utxU5o0XMNPFubKlvPQumK3F+A5i\n"
          "cL2ujCOm4+RqLt0nyp90QUoanQKBgQDVG28wtJxVnSnPYAOCkZvRiqyCsWGiAERf\n"
          "8FrKz7AttWGlwrditolsenpyqicjjaRnvULlHQNeLjchXKAWRh7TR/PqoLuMlfhK\n"
          "6MqB3NmvNQKgJ9rkyICzXN2RBGwyj/X5++SGOCCgdJ4rHbb3QL4Iof8CQlCMN+fg\n"
          "PLruS8MB3QKBgQC+c86cJKo7CuSmPkY65vW+d+PKUIDLLwpPpmNBnH394KLk0gpN\n"
          "FNt5Ol2WA6X4VY9QnScPeHWfqCP0crmnz06OIxrmYQdM0TVzSjNZ3YftTtPuVy6U\n"
          "ag49f4pmESK9Dueei8jd9JDUSYeYaWvysNcJJqPY/57Cb7798L+Z/2wmJQKBgETg\n"
          "rxlw5q6NM3xBLiE/artZNNSw/DteFrtjdhTi97BuVXc77gXLtbMICxeQg0Hsf9y/\nwSVIMVR5X3w68csBMula8i09ciDIQA4GG53JgdotKgIVn5weaeqO81Xxtf7JpNj9\n"
          "Xyk6buEtkAmjewWDOWiU41UZlescDqfdORXYCtlJAoGAK6i6Nnb8Gk0xO93oxh8I\n"
          "O2fNZJ5olH1Ex6JuzUknHunj/Z2A6pfeoV8C6hQB1r6lNehB9uU3Ftz2fH0jXrl4\n"
          "Glr+uMNk1ov8Di8GecNmVEchyfbTEj/kvoyptkMrO6iKv2plbhI+sE259Him6AuL\n"
          "JSSYfCCWaS5z4eeRu5+soa4=\n"
          "-----END PRIVATE KEY-----\n",
      "client_email": "firebase-adminsdk-fbsvc@tutoring-e52e6.iam.gserviceaccount.com",
      "client_id": "103475901345221584630",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
    };

    final accountCredentials =
    auth.ServiceAccountCredentials.fromJson(serviceAccountMap);

    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

    try {
      final client = await auth.clientViaServiceAccount(accountCredentials, scopes);
      final accessToken = client.credentials.accessToken.data;

      final url = 'https://fcm.googleapis.com/v1/projects/tutoring-e52e6/messages:send';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

      final payload = {
        'message': {
          'token': fcmToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'channel_id': 'high_importance_channel',
              'default_sound': true,
              'default_vibrate_timings': true,
            },
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'type': 'test_push',
          },
        },
      };

      _log('====== [GOOGLE FCM REQUEST] ======\n'
          'URL: $url\n'
          'Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      client.close();

      _log('====== [GOOGLE FCM RESPONSE] ======\n'
          'Status: ${response.statusCode}\n'
          'Body: ${response.body}');

      if (response.statusCode == 200) {
        return {'success': true, 'msg': 'Google FCM 發送成功'};
      } else {
        final dynamic resBody = jsonDecode(response.body);
        final errMsg = resBody['error']?['message'] ?? '發送失敗';
        return {'success': false, 'msg': errMsg};
      }
    } catch (e) {
      _log('Google FCM 發送異常: $e');
      return {'success': false, 'msg': '發送 Google FCM 異常: $e'};
    }
  }


  /// 新增 / 更新簽名 API (POST /api/tutoring/users/signature)
  static Future<Map<String, dynamic>> uploadSignature({
    required Uint8List imageBytes,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/tutoring/users/signature');
    final request = http.MultipartRequest('POST', url);

    // Headers 設定
    request.headers.addAll({
      'Authorization': 'Bearer $commonToken',
      'X-API-Key': xApiKey,
      'X-User-No': userNo,
      'X-Role-Code': roleCode,
    });

    // ─── 產生符合規格的檔名：S{USER_NO}_{yyyyMMddHHmmssfff}.png ───
    final now = DateTime.now();
    final yyyy = now.year.toString().padLeft(4, '0');
    final MM = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    final HH = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final fff = now.millisecond.toString().padLeft(3, '0');
    final timestamp = '$yyyy$MM$dd$HH$mm$ss$fff';

    // 組合範例：S0900000001_20260819113910888.png
    final targetFilename = 'S${userNo}_$timestamp.png';

    // 夾帶至 multipart 欄位名為 'file'
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: targetFilename,
        contentType: MediaType('image', 'png'),
      ),
    );

    _log('====== [HTTP REQUEST] 上傳簽名檔 ======\n'
        'URL: $url\n'
        'Headers: ${request.headers}\n'
        'Generated Filename: $targetFilename\n'
        'Bytes length: ${imageBytes.length}');

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      _log('====== [HTTP RESPONSE] 上傳簽名檔 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body: $decoded');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'msg': '回傳格式異常'};
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 上傳簽名檔失敗 ======\nError: $e\n$stack');
      return {'success': false, 'msg': '上傳失敗，請檢查網路連線'};
    }
  }

  /// 移除 FCM Token API (DELETE /api/tutoring/users/fcm)
  static Future<Map<String, dynamic>> deleteFcmToken({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/users/fcm';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 移除 FCM Token ======\n'
        'URL: $url\n'
        'Method: DELETE\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .delete(
        Uri.parse(url),
        headers: headers,
      )
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 移除 FCM Token ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

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
      _log('====== [HTTP ERROR] 移除 FCM Token 異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {
        "success": false,
        "msg": "網路連線失敗，請檢查網路狀態或稍後再試。",
        "data": null,
      };
    }
  }

  /// 取得家長所屬學生列表 (GET /api/tutoring/students)
  static Future<StudentListResponse> getStudents({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/students';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得學生列表 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得學生列表 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return StudentListResponse.fromJson(decoded);
      } else {
        return StudentListResponse(
          success: false,
          msg: '伺服器回傳格式不正確',
          data: null,
        );
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得學生列表異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return StudentListResponse(
        success: false,
        msg: '網路連線失敗，請檢查網路狀態或稍後再試。',
        data: null,
      );
    }
  }

  /// 取得聊天室列表 API (GET /api/tutoring/chats)
  static Future<ChatListResponse> getChats({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/chats';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得聊天室列表 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得聊天室列表 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return ChatListResponse.fromJson(decoded);
      } else {
        return ChatListResponse(
          success: false,
          msg: '伺服器回傳格式不正確',
          data: null,
        );
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得聊天室列表異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return ChatListResponse(
        success: false,
        msg: '網路連線失敗，請檢查網路狀態或稍後再試。',
        data: null,
      );
    }
  }


  /// 取得聊天室歷史訊息 API (GET /api/tutoring/chats/{chatId}/messages)
  static Future<Map<String, dynamic>> getChatMessages({
    required String chatId,
    String? before,
    int limit = 30,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    // 組合 URL 與 Query Parameters
    String urlStr = '$baseUrl/api/tutoring/chats/$chatId/messages?limit=$limit';
    if (before != null && before.isNotEmpty) {
      urlStr += '&before=$before';
    }

    final url = Uri.parse(urlStr);
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得聊天室訊息 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      _log('====== [HTTP RESPONSE] 取得聊天室訊息 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body: $decoded');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {"success": false, "msg": "伺服器回傳格式不正確", "data": null};
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得聊天室訊息異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {"success": false, "msg": "網路連線失敗，請檢查網路狀態或稍後再試。", "data": null};
    }
  }


  /// 發送聊天室文字訊息 API (POST /api/tutoring/chats/{chatId}/messages)
  static Future<Map<String, dynamic>> sendChatMessage({
    required String chatId,
    required String text,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/chats/$chatId/messages';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );
    final requestBody = {
      'type': 'text',
      'text': text,
    };

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 發送聊天室訊息 ======\n'
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

      _log('====== [HTTP RESPONSE] 發送聊天室訊息 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

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
      _log('====== [HTTP ERROR] 發送聊天室訊息發生異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return {
        "success": false,
        "msg": "網路連線失敗，請檢查網路狀態或稍後再試。",
        "data": null,
      };
    }
  }

  /// 發送聊天室圖片訊息 API (POST /api/tutoring/chats/{chatId}/messages)
  static Future<Map<String, dynamic>> sendChatImageMessage({
    required String chatId,
    required String filePath,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = Uri.parse('$baseUrl/api/tutoring/chats/$chatId/messages');
    final request = http.MultipartRequest('POST', url);

    // 設定 Headers
    request.headers.addAll({
      'Authorization': 'Bearer $commonToken',
      'X-API-Key': xApiKey,
      'X-User-No': userNo,
      'X-Role-Code': roleCode,
    });

    // 附加 Form Data 欄位與檔案
    request.fields['type'] = 'image';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    _log('====== [HTTP REQUEST] 發送聊天室圖片 ======\nURL: $url\nFilePath: $filePath');

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

      _log('====== [HTTP RESPONSE] 發送聊天室圖片 ======\nStatus: ${response.statusCode}\nBody: $decoded');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'success': false, 'msg': '回傳格式異常'};
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 發送圖片失敗 ======\nError: $e\n$stack');
      return {'success': false, 'msg': '圖片上傳失敗，請檢查網路連線'};
    }
  }

  /// 收回聊天室訊息 API (DELETE /api/tutoring/chats/{chatId}/messages/{messageId})
  static Future<Map<String, dynamic>> recallChatMessage({
    required String chatId,
    required String messageId,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/chats/$chatId/messages/$messageId';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    _log('====== [HTTP REQUEST] 收回聊天室訊息 ======\nURL: $url\nMethod: DELETE');

    try {
      final response = await http
          .delete(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      _log('====== [HTTP RESPONSE] 收回聊天室訊息 ======\nStatus: ${response.statusCode}\nBody: $decoded');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      } else {
        return {"success": false, "msg": "伺服器回傳格式不正確", "data": null};
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 收回聊天室訊息發生異常 ======\nError: $e\nStackTrace: $stack');
      return {"success": false, "msg": "網路連線失敗，請檢查網路狀態或稍後再試。", "data": null};
    }
  }
}