import 'dart:developer' as developer;
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

/// Android 高優先級推播通知頻道（使前景收到時能彈出浮動橫幅與發出聲音）
const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
  'high_importance_channel',
  '高優先推播通知',
  description: '用於接收即時推播通知',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

/// 頂層背景推播處理函式
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('[FCM Background] 收到背景通知: ${message.messageId}', name: 'FCM');
}

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. 註冊 FCM 背景處理
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. 初始化 Flutter Local Notifications (v22.x)
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // 👈 修正處：改為具名參數 settings: initSettings
    await flutterLocalNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('[Notification Click] 使用者點擊橫幅: ${response.payload}', name: 'FCM');
      },
    );

    // 3. 建立 Android Notification Channel
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(highImportanceChannel);

      // Android 13+ (API 33+) 請求通知權限
      if (Platform.isAndroid) {
        final granted = await androidImplementation.requestNotificationsPermission();
        developer.log('[FCM] Android 本地通知權限狀態: $granted', name: 'FCM');
      }
    }

    // 4. 請求 Firebase Messaging 權限
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    developer.log('[FCM] Firebase 授權狀態: ${settings.authorizationStatus}', name: 'FCM');

    // 5. iOS 前景顯示設定
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 6. 監聽前景訊息：收到 FCM 時立即呼叫 local notification 彈出橫幅
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log(
        '[FCM Foreground] 收到訊息: ${message.notification?.title} - ${message.notification?.body}',
        name: 'FCM',
      );

      final RemoteNotification? notification = message.notification;
      final AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              highImportanceChannel.id,
              highImportanceChannel.name,
              channelDescription: highImportanceChannel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 7. 取得並存下 Device Token
    await getAndSaveToken();
  }

  static Future<String?> getAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        developer.log('[FCM Token] $token', name: 'FCM');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', token);
      }
      return token;
    } catch (e) {
      developer.log('[FCM Token Error] 取得失敗: $e', name: 'FCM');
      return null;
    }
  }
}