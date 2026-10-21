import 'dart:io';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'API/auth_service.dart';
import '共用函式/GlobalDeviceSwitcher.dart';
import '共用函式/app_utils.dart';
import '共用函式/fcm_service.dart';
import '共用函式/storage_service.dart';
import '家長/parent_home_page.dart';
import '老師/teacher_home_page.dart';
import '登入/LoginPage.dart';
import '登入/RoleSelectionPage.dart';

/// 🔑 全域 navigatorKey[cite: 29]
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host == 'wilson-edu.com' || host.contains('wilson-edu.com')) {
          return true;
        }
        return false;
      };
  }
}


void main() async{
  // 1. DevicePreview 僅在 Debug 模式開啟[cite: 29]
  DevicePreview.enable(enabled: kDebugMode);

  // 2. 初始化 Binding[cite: 29]
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 初始化 Firebase & FCM 推播
  try {
    await Firebase.initializeApp();
    await FcmService.init();
  } catch (e) {
    debugPrint('Firebase 初始化異常 (若未放 google-services.json/GoogleService-Info.plist 請先配置): $e');
  }

  // 3. 全域注入 HttpOverrides[cite: 29]
  HttpOverrides.global = MyHttpOverrides();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    kDebugMode
        ? const GlobalDeviceSwitcherOverlay(child: RestartWidget(child: MyApp()))
        : const RestartWidget(child: MyApp()),
  );
}

class RestartWidget extends StatefulWidget {
  final Widget child;

  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    context.findAncestorStateOfType<_RestartWidgetState>()?.restartApp();
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() {
    setState(() {
      _key = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final mediaQuery = MediaQuery.maybeOf(context);
        final size = mediaQuery?.size ??
            WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
        final isLandscape = size.width > size.height;
        final designSize =
        isLandscape ? const Size(812, 375) : const Size(375, 812);

        return ScreenUtilPlusInit(
          designSize: designSize,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              title: 'Wilson Education',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                scaffoldBackgroundColor: Colors.white,
                fontFamily: 'Roboto',
              ),
              builder: (context, widget) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: widget ?? const SizedBox.shrink(),
                );
              },
              home: const WelcomePage(),
            );
          },
        );
      },
    );
  }
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  /// 啟動流程：鎖定 2 秒歡迎展示，同時在背景執行分流與自動登入檢查[cite: 29]
  Future<void> _startSplashSequence() async {
    final timerFuture = Future.delayed(const Duration(milliseconds: 2000));
    final targetPageFuture = _resolveTargetPage();

    final results = await Future.wait([timerFuture, targetPageFuture]);

    if (!mounted) return;

    final targetPage = results[1] as Widget;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => targetPage,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  // 在 main.dart 中的 _resolveTargetPage 函式

  Future<Widget> _resolveTargetPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      // 1. 未登入狀態 -> 登入頁
      if (!isLoggedIn) {
        return const LoginPage();
      }

      // 先把原本快取的身分取出來
      // 注意：您之前的程式碼家長有時用 'M' 有時用 'P'，建議統一。這裡先同時支援。
      final savedRoleCode = prefs.getString('role_code') ?? '';
      final userNm = prefs.getString('user_nm') ?? '';

      // 2. 已登入狀態 -> 嘗試換取今日最新 API Key
      final savedCredentials = await StorageService.getSavedCredentials();
      final phone = savedCredentials['phone'] ?? prefs.getString('user_no') ?? '';
      final password = savedCredentials['password'] ?? '';

      if (phone.isNotEmpty && password.isNotEmpty) {
        try {
          final res = await AuthService.login(userNo: phone, password: password);
          if (res.success && res.data != null) {
            final data = res.data!;
            await prefs.setString('user_no', data.userNo);
            await prefs.setString('user_nm', data.userNm);
            await prefs.setString('xApiKey', data.xApiKey);
            await prefs.setString('x_api_key', data.xApiKey);
            await prefs.setString('picLink', data.picLink);
            await prefs.setString('signLink', data.signLink);

            // 核心修正點：如果原本已經有選擇身份，就尊重使用者的選擇，不要覆蓋
            if (savedRoleCode.isNotEmpty) {
              // 依照保留的身份進入首頁
              if (savedRoleCode == 'P' || savedRoleCode == 'M') {
                return ParentHomePage(userName: data.userNm);
              } else {
                return TeacherHomePage(userName: data.userNm);
              }
            }

            // ---------- 以下是第一次登入 (沒有 savedRoleCode) 的處理邏輯 ----------

            // 如果是多重身份，且沒有選擇過，導向選擇頁
            if (data.hasMultipleRoles) {
              return RoleSelectionPage(loginData: data);
            }

            // 單一身份的處理
            final currentRole = data.hasParentRole
                ? 'P' // 建議統一使用 'P' 代表家長
                : (data.schools.isNotEmpty ? data.schools.first.roleCode : 'T');

            await prefs.setString('role_code', currentRole);

            if (currentRole == 'P' || currentRole == 'M') {
              return ParentHomePage(userName: data.userNm);
            } else {
              return TeacherHomePage(userName: data.userNm);
            }
          }
        } catch (_) {
          // 網路連線異常時，使用本機快取身分降級進入
        }
      }

      // 3. 快取身分回退判斷 (自動登入失敗，但之前有登入過)
      if (savedRoleCode == 'P' || savedRoleCode == 'M') {
        return ParentHomePage(userName: userNm);
      } else {
        return TeacherHomePage(userName: userNm);
      }
    } catch (_) {
      return const LoginPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    final isTablet = shortestSide >= 600;

    // 📱 iPhone vs 📟 iPad 自動適配比例：
    // iPad 上取較寬比例，避免手機設計尺寸在平板顯得過小；iPhone 保持適中大小
    final logoWidth = isTablet ? shortestSide * 0.42 : 220.w;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SizedBox.expand(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                const Spacer(flex: 3),
                Center(
                  child: Image.asset(
                    'assets/webp/1.webp',
                    width: logoWidth,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'Wilson Education',
                        style: TextStyle(
                          fontSize: isTablet ? 32.sp : 24.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2979FF),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(flex: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Copyrights ©2024 All Rights Reserved by Wilson Inc.',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: TextStyle(
                      color: const Color(0xFF212121),
                      fontSize: isTablet ? 15.sp : 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: isTablet ? 30.h : 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}