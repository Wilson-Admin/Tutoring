import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../共用函式/app_dialog.dart'; // 若 forceLogout 放置的檔案路徑不同請依實際位置調整
import '../共用函式/app_utils.dart';
import '../資料結構/ChatListResponse.dart';
import '../資料結構/NoticeResponse.dart';
import '../資料結構/Structures.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;

import '../資料結構/StudentListResponse.dart';
import '../資料結構/SurveyDetailResponse.dart';
import '../資料結構/SurveyResponse.dart';

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
    // 替換為新的 service account json 內容
    final serviceAccountMap = {
      "type": "service_account",
      "project_id": "tutoring-e52e6",
      "private_key_id": "5127a4f242ae6592f361a80324c282e1e668e9a0",
      "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCtgNqoZbM7VPzn\ngQq5WYO+/itmLmqcjTEwa08hWiMcY9pWgrOPtpjZ2Kml+QRdzqh3cAS1JNPiVaAi\nKwG99hADAMOM5u7woLcxHVl1ChUso+U8slh6hUuLv4+7O+vSa9/IHiGDN90AYfqB\ncyxmgmwkmiYSyUDAC9J0m4MdplvHlovDAkxaSFA47UXtGxq2Rmu6WVX+TC99W+5c\nB3+SamMhUTQ4fSYr4YIn2nmbVWNeHJgJ0dTDS5ncX594nYIysaVokLZX1GCyUSz3\nk9/yQjNqKEnJJKb1GNdCOAq7lbrzNhhHiCEk96bRAGfgtXS41MEu/fNeyb2M7b8f\n7ti7nwV5AgMBAAECggEAEAlkbIM17Up+M8GsJZSeBkXE6iVpKj4sqT6J6lnD/AhI\nso1THnnwp9YMXDBnlGoZDS0X6kxUn0ttySqzdwTq1vQ3nurrc+dO92Wwko5ThbRC\naHlNj0mJwYl7tgEkW2coIH2UeGXt8e6ccmGcXX85kqqC0WKzruyIz8ld9ZweSJS9\nH079KvxnQ0ibZbe2HZDjkkBzSOr42ie+GFdYSsj3IZ4d+1Sr3NQI8Lt7v/KbXZTh\nDm960kV36YT5dxar2DzgDXJQiqe4yEAxHLzL9sNT3gXw8beYz4f4HfKksJVGBPLF\nD1NFcaQbArV9odVPtiM60jjKKP9ZddC9JqlD16ZOzwKBgQDf6FK1K23IBQj33Qg0\nFuKROPfvFZCdMGatVz8mdQfZrxd/YyTGxKE6u21KnDJdlI/KhdSy8AasM4JNIHq2\ni5OaJvvNs5R9NWQJ5+Ahj52UFOLJianF+Gkn1z5BINfh6htLFEeqJ+gq2NEmZxPe\ntji3bENfqB8cVnQXijViOH8+FwKBgQDGXxZEKTrV+jXMhF+SEQKlWvwe0PiFw8Bl\nK4SY1wIkP0S7g08RIn7mQLBb90g97IhGZEqAm4j2PUAA1wq69pos4gM2Ud7WXe2x\nMLZa+76maxDCge9JlEnD1XFnQIO2afTJb1V6hWT+i3H+XvzTtuENm8eu4CrE1RiP\nVLVdCDMi7wKBgQCuN8WK4+TCmnBU8+27IgdeObZomB3ywMNToqwnTy4xiZQ98TWf\nV0WgPk+WmxxxRfPv/9v08uAuQtHjEx+IQ+gwLJ8GefFSzyUss/foBSf2HZ4sdGnd\n+SBQ+KCe6mAvjwl3jKsKUYzLMfLi75c9VgmhZqKxnk2+reIcotRQvWb8NwKBgAC+\nnqDG3teqxsTrwkgUFER2oPekpSorX++BSFAijnmAW0uw5H0V+g/3MjJGLVk+KAzL\nl5QAAXWbKUBXjkzBXDbK6mQrzoBTfe7qVeTliQOq5zczsag/DD/V70UJ8vSeVTLk\nXhfFpGloMJdZ1+0bhKC+cvNvF/oBKsRu9vdQbpC1AoGATDN51clY4b/X4PCDrQDG\nOjYuiOCh5VRPYhVLbKFiYWXZeGCQRDZLM1Y4rxYs60Bz/QNtW27OlA58RZeVVSzI\n/xa/I8/uFsbBr7UP0s4XcutCBxXUWcrvM36ZwCguzUeqsHp0DYYn0zIioRq3tdM2\nRcnbm3LzkYvYU/khNINbDlQ=\n-----END PRIVATE KEY-----\n",
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


  /// 取得 APP 有效公告列表 (GET /api/tutoring/notices/active)
  static Future<NoticeResponse> getActiveNotices({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/notices/active';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得有效公告列表 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得有效公告列表 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return NoticeResponse.fromJson(decoded);
      } else {
        return NoticeResponse(
          success: false,
          msg: '伺服器回傳格式不正確',
          data: null,
        );
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得有效公告列表異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return NoticeResponse(
        success: false,
        msg: '網路連線失敗，請檢查網路狀態或稍後再試。',
        data: null,
      );
    }
  }
  /// 取得家長有效問卷列表 (GET /api/tutoring/surveys/active)
  static Future<SurveyResponse> getActiveSurveys({
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/surveys/active';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得有效問卷列表 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 15));

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得有效問卷列表 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return SurveyResponse.fromJson(decoded);
      } else {
        return SurveyResponse(
          success: false,
          msg: '伺服器回傳格式不正確',
          data: null,
        );
      }
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得有效問卷列表異常 ======\n'
          'Error: $e\n'
          'StackTrace: $stack');
      return SurveyResponse(
        success: false,
        msg: '網路連線失敗，請檢查網路狀態或稍後再試。,',
        data: null,
      );
    }
  }

  /// 取得未填寫問卷表單內容 (GET /api/tutoring/surveys/{surveyNo}/form?csNo={csNo})
  /// 取得未填寫問卷表單內容 (GET /api/tutoring/surveys/{surveyNo}/form?csNo={csNo})
  static Future<SurveyDetailResponse> getSurveyForm({
    required String surveyNo,
    required String csNo,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/surveys/$surveyNo/form?csNo=$csNo';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得未填寫問卷表單 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得未填寫問卷表單 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return SurveyDetailResponse.fromJson(decoded);
      }
      return SurveyDetailResponse(success: false, msg: '伺服器回傳格式不正確', data: null);
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得未填寫問卷表單異常 ======\nError: $e\nStackTrace: $stack');
      return SurveyDetailResponse(success: false, msg: '網路連線失敗，請稍後再試。', data: null);
    }
  }

  /// 取得已填寫問卷歷史記錄 (GET /api/tutoring/surveys/{surveyNo}/history?csNo={csNo})
  static Future<SurveyDetailResponse> getSurveyHistory({
    required String surveyNo,
    required String csNo,
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/surveys/$surveyNo/history?csNo=$csNo';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    _log('====== [HTTP REQUEST] 取得已填寫問卷歷史 ======\n'
        'URL: $url\n'
        'Method: GET\n'
        'Headers:\n${encoder.convert(headers)}');

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final prettyResponseBody = encoder.convert(decoded);

      _log('====== [HTTP RESPONSE] 取得已填寫問卷歷史 ======\n'
          'Status Code: ${response.statusCode}\n'
          'Body:\n$prettyResponseBody');

      _handleAuthExpired(decoded);

      if (decoded is Map<String, dynamic>) {
        return SurveyDetailResponse.fromJson(decoded);
      }
      return SurveyDetailResponse(success: false, msg: '伺服器回傳格式不正確', data: null);
    } catch (e, stack) {
      _log('====== [HTTP ERROR] 取得已填寫問卷歷史異常 ======\nError: $e\nStackTrace: $stack');
      return SurveyDetailResponse(success: false, msg: '網路連線失敗，請稍後再試。', data: null);
    }
  }


  /// 家長提交問卷答案 (POST /api/tutoring/surveys/{surveyNo}/responses)
  static Future submitSurvey({
    required String surveyNo,
    required String csNo,
    required Map<int, int> answers, // key: questionSr, value: optionSr
    required String userNo,
    required String xApiKey,
    required String roleCode,
  }) async {
    final url = '$baseUrl/api/tutoring/surveys/$surveyNo/responses';
    final headers = _buildHeaders(
      xApiKey: xApiKey,
      xUserNo: userNo,
      xRoleCode: roleCode,
    );

    const encoder = JsonEncoder.withIndent('  ');

    // 依照 API 規格將 answers Map 轉成 List
    final List answerList = answers.entries.map((e) => {
    'questionSr': e.key,
    'optionSr': e.value,
    }).toList();

    final requestBody = {
    'csNo': csNo,
    'answers': answerList,
    };

    _log('====== [HTTP REQUEST] 提交問卷 ======\n'
    'URL: $url\n'
    'Method: POST\n'
    'Headers:\n${encoder.convert(headers)}\n'
    'Body:\n${encoder.convert(requestBody)}');

    try {
    final response = await http.post(
    Uri.parse(url),
    headers: headers,
    body: jsonEncode(requestBody),
    ).timeout(const Duration(seconds: 15));

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final prettyResponseBody = encoder.convert(decoded);

    _log('====== [HTTP RESPONSE] 提交問卷 ======\n'
    'Status Code: ${response.statusCode}\n'
    'Body:\n$prettyResponseBody');

    _handleAuthExpired(decoded);

    if (decoded is Map<String, dynamic>) {
    return decoded;
    }
    return {'success': false, 'msg': '伺服器回傳格式不正確'};
    } catch (e, stack) {
    _log('====== [HTTP ERROR] 提交問卷異常 ======\nError: $e\nStackTrace: $stack');
    return {'success': false, 'msg': '網路連線失敗，請檢查網路狀態或稍後再試。'};
    }
  }
}