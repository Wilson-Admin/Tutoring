import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../共用函式/app_dialog.dart';
import '../共用函式/storage_service.dart';
import '../家長/parent_home_page.dart';
import '../老師/teacher_home_page.dart';
import 'RoleSelectionPage.dart';

class LoginPage extends StatefulWidget {
  final String roleTitle;

  const LoginPage({super.key, this.roleTitle = '登入'});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _versionInfo = '';

  @override
  void initState() {
    super.initState();
    _loadCredentials();
    _loadVersionInfo();
  }

  Future<void> _loadCredentials() async {
    final savedData = await StorageService.getSavedCredentials();
    if (savedData['rememberMe'] == true && mounted) {
      setState(() {
        _rememberMe = true;
        _phoneController.text = savedData['phone'] ?? '';
        _passwordController.text = savedData['password'] ?? '';
      });
    }
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _versionInfo = 'v${info.version} (${info.buildNumber})';
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      AppDialog.show(message: '請輸入手機號碼與密碼');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.login(
        userNo: phone,
        password: password,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        await StorageService.saveCredentials(
          phone: phone,
          password: password,
          rememberMe: _rememberMe,
        );

        final data = response.data!;
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('user_no', data.userNo);
        await prefs.setString('user_nm', data.userNm);
        await prefs.setString('xApiKey', data.xApiKey);
        await prefs.setString('x_api_key', data.xApiKey);
        await prefs.setString('picLink', data.picLink);
        await prefs.setString('signLink', data.signLink);
        await prefs.setBool('is_logged_in', true);

        final currentRole = data.hasParentRole
            ? 'M'
            : (data.schools.isNotEmpty ? data.schools.first.roleCode : 'T');
        await prefs.setString('role_code', currentRole);

        if (!mounted) return;

        // 登入成功：不彈出 Dialog，直接跳轉對應首頁
        if (data.hasMultipleRoles) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RoleSelectionPage(loginData: data),
            ),
          );
        } else if (data.hasParentRole) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ParentHomePage(userName: data.userNm),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherHomePage(userName: data.userNm),
            ),
          );
        }
      } else {
        // 登入失敗：彈出 Dialog
        AppDialog.show(
          title: '登入失敗',
          message: response.msg.isEmpty ? '帳號或密碼錯誤，請重新確認。' : response.msg,
        );
      }
    } catch (e) {
      if (mounted) {
        // 異常錯誤：彈出 Dialog
        AppDialog.show(
          title: '連線異常',
          message: '連線發生異常：\n$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    minWidth: constraints.maxWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 36.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 20.h),
                            Center(
                              child: Image.asset(
                                'assets/webp/2.webp',
                                width: 100.w,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 100.w,
                                  height: 80.h,
                                  color: Colors.grey.shade100,
                                  alignment: Alignment.center,
                                  child: Text(
                                    'LOGO',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF1976D2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    '歡迎',
                                    style: TextStyle(
                                      fontSize: 26.sp,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2979FF),
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    widget.roleTitle,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: const Color(0xFF757575),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 24.h),
                            Text(
                              '手機號碼',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF616161),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: '請輸入手機號碼',
                                hintStyle: TextStyle(
                                  fontSize: 15.sp,
                                  color: const Color(0xFFBDBDBD),
                                ),
                                fillColor: const Color(0xFFF1F4F8),
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              '密碼',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: const Color(0xFF616161),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textAlignVertical: TextAlignVertical.center,
                              style: TextStyle(fontSize: 16.sp),
                              decoration: InputDecoration(
                                hintText: '請輸入密碼',
                                hintStyle: TextStyle(
                                  fontSize: 15.sp,
                                  color: const Color(0xFFBDBDBD),
                                ),
                                fillColor: const Color(0xFFF1F4F8),
                                filled: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide.none,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF757575),
                                    size: 22.sp,
                                  ),
                                  splashRadius: 20.r,
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => setState(
                                          () => _rememberMe = !_rememberMe),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '記住我',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: _rememberMe
                                              ? const Color(0xFF1E88E5)
                                              : const Color(0xFF616161),
                                        ),
                                      ),
                                      SizedBox(width: 6.w),
                                      Icon(
                                        _rememberMe
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        size: 20.sp,
                                        color: _rememberMe
                                            ? const Color(0xFF1E88E5)
                                            : const Color(0xFF9E9E9E),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20.h),
                            SizedBox(
                              width: double.infinity,
                              height: 52.h,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF4A84D3),
                                      Color(0xFF274D95)
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(14.r),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? SizedBox(
                                    width: 24.w,
                                    height: 24.w,
                                    child:
                                    const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                      : Text(
                                    '登入',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_versionInfo.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              Center(
                                child: Text(
                                  _versionInfo,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: const Color(0xFF9E9E9E),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                text: TextSpan(
                                  text: '登入即代表同意 ',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF757575),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: '服務條款',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: const Color(0xFF1E88E5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    TextSpan(
                                        text: ' 與 ',
                                        style: TextStyle(fontSize: 13.sp)),
                                    TextSpan(
                                      text: '隱私政策',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: const Color(0xFF1E88E5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}