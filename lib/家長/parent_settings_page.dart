import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutoring/API/auth_service.dart';
import 'package:tutoring/main.dart';
import 'package:tutoring/登入/LoginPage.dart';

import '../共用函式/app_dialog.dart';

class ParentSettingsPage extends StatefulWidget {
  const ParentSettingsPage({super.key});

  @override
  State<ParentSettingsPage> createState() => _ParentSettingsPageState();
}

class _ParentSettingsPageState extends State<ParentSettingsPage> {
  int _tabIndex = 0; // 0: 帳號相關, 1: 個人資訊
  bool _isLoading = false;

  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAccount();
  }

  Future<void> _loadUserAccount() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserNo = prefs.getString('user_no') ?? prefs.getString('saved_user_phone') ?? '';
    setState(() {
      _accountController.text = savedUserNo;
    });
  }

  @override
  void dispose() {
    _accountController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 變更密碼處理邏輯（全面使用 AppDialog）
  Future<void> _handleChangePassword() async {
    final userNo = _accountController.text.trim();
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

    if (userNo.isEmpty || oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      AppDialog.show(title: '提示', message: '請填寫完整帳號與密碼資訊');
      return;
    }

    if (!alphanumericRegex.hasMatch(userNo) || !alphanumericRegex.hasMatch(newPassword)) {
      AppDialog.show(title: '提示', message: '帳號與密碼僅接受英文字母及數字');
      return;
    }

    if (newPassword != confirmPassword) {
      AppDialog.show(title: '提示', message: '新密碼與確認密碼不一致。');
      return;
    }

    if (newPassword == oldPassword) {
      AppDialog.show(title: '提示', message: '新密碼不可與目前密碼相同。');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final xApiKey = prefs.getString('x_api_key') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      final res = await AuthService.changePassword(
        userNo: userNo,
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // 清除登入狀態，強制下次重新登入
        await prefs.remove('token');
        await prefs.remove('user_token');
        await prefs.setBool('is_logged_in', false);
        await prefs.remove('is_logged_in');
        await prefs.remove('saved_user_password');

        if (!mounted) return;

        final msg = res['msg']?.toString() ?? '密碼變更成功，請使用新密碼重新登入。';

        // 成功以 Dialog 顯示並於確定後返回 LoginPage
        await AppDialog.show(
          title: '密碼修改成功',
          message: msg,
          confirmText: '前往登入',
          onConfirm: () {
            if (!mounted) return;
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
            );
            RestartWidget.restartApp(context);
          },
        );
      } else {
        final errorMsg = res['msg']?.toString() ?? '密碼變更失敗，請稍後再試。';
        AppDialog.show(title: '變更失敗', message: errorMsg);
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(title: '連線異常', message: '連線發生異常，請稍後再試：\n$e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 執行登出（使用 AppDialog.showConfirm）
  Future<void> _handleLogout() async {
    final shouldLogout = await AppDialog.showConfirm(
      context: context,
      title: '確定登出？',
      message: '登出後將返回初始畫面，已儲存的登入資訊將妥善保留。',
      confirmText: '確定',
      cancelText: '取消',
    );

    if (shouldLogout && mounted) {
      final prefs = await SharedPreferences.getInstance();

      final isRemembered = prefs.getBool('saved_remember_me') ?? false;
      final savedPhone = prefs.getString('saved_user_phone');
      final savedPassword = prefs.getString('saved_user_password');

      await prefs.remove('token');
      await prefs.remove('user_token');
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('is_logged_in');

      if (isRemembered && savedPhone != null) {
        await prefs.setBool('saved_remember_me', true);
        await prefs.setString('saved_user_phone', savedPhone);
        if (savedPassword != null) {
          await prefs.setString('saved_user_password', savedPassword);
        }
      }

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
      );

      RestartWidget.restartApp(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
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
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 0),
                            child: Container(
                              height: 46.h,
                              decoration: BoxDecoration(
                                color: _tabIndex == 0 ? const Color(0xFF6C63FF) : const Color(0xFFDCDAFE),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '帳號相關',
                                style: TextStyle(
                                  color: _tabIndex == 0 ? Colors.white : const Color(0xFF6C63FF),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 1),
                            child: Container(
                              height: 46.h,
                              decoration: BoxDecoration(
                                color: _tabIndex == 1 ? const Color(0xFF00B074) : const Color(0xFFD6F5E8),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '個人資訊',
                                style: TextStyle(
                                  color: _tabIndex == 1 ? Colors.white : const Color(0xFF00B074),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    _tabIndex == 0 ? _buildAccountTab() : _buildProfileTab(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 1. 帳號相關 ====================
  Widget _buildAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('帳號'),
        SizedBox(height: 8.h),
        _buildInputField(controller: _accountController),
        SizedBox(height: 20.h),

        _buildSectionHeader('目前密碼'),
        SizedBox(height: 8.h),
        _buildInputField(
          controller: _oldPasswordController,
          isPassword: true,
          obscureText: _obscureOldPassword,
          onToggleVisibility: () {
            setState(() => _obscureOldPassword = !_obscureOldPassword);
          },
        ),
        SizedBox(height: 20.h),

        _buildSectionHeader('新密碼'),
        SizedBox(height: 8.h),
        _buildInputField(
          controller: _newPasswordController,
          isPassword: true,
          obscureText: _obscureNewPassword,
          onToggleVisibility: () {
            setState(() => _obscureNewPassword = !_obscureNewPassword);
          },
        ),
        SizedBox(height: 20.h),

        _buildSectionHeader('確認新密碼'),
        SizedBox(height: 8.h),
        _buildInputField(
          controller: _confirmPasswordController,
          isPassword: true,
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
        SizedBox(height: 20.h),

        _buildSectionHeader('預設簽名'),
        SizedBox(height: 8.h),
        Container(
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF3872F6), width: 1.5),
          ),
        ),
        SizedBox(height: 10.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                '修改簽名',
                style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF00A3FF),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '384 × 140',
                style: TextStyle(fontSize: 13.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        _buildSectionHeader('預設大頭照'),
        SizedBox(height: 14.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 36.sp, color: Colors.white),
            ),
            SizedBox(width: 16.w),
            Column(
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 90.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B2B48),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '更換照片',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 90.w,
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB0B8C5),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '刪除照片',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 32.h),

        ElevatedButton(
          onPressed: _isLoading ? null : _handleChangePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9E9BF8),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          child: _isLoading
              ? SizedBox(
            height: 20.h,
            width: 20.h,
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Text(
            '儲存',
            style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(height: 12.h),

        Center(
          child: TextButton(
            onPressed: _handleLogout,
            child: Text(
              '登出',
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFFFF5252),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  // ==================== 2. 個人資訊 ====================
  Widget _buildProfileTab() {
    return Column(
      children: [
        _buildStudentCard(
          name: '王小明',
          schoolInfo: '文元國小3年7班',
          teachers: [
            {'subject': '課輔', 'name': '王怡君 老師', 'color': const Color(0xFF60A5FA)},
            {'subject': '美語', 'name': '陳怡君 老師', 'color': const Color(0xFFFBBF24)},
            {'subject': '數學', 'name': '林怡君 老師', 'color': const Color(0xFF60A5FA)},
            {'subject': '作文', 'name': '黃怡君 老師', 'color': const Color(0xFFFBBF24)},
          ],
        ),
        SizedBox(height: 16.h),
        _buildStudentCard(
          name: '王小華',
          schoolInfo: '文元國小1年5班',
          teachers: [
            {'subject': '課輔', 'name': '王怡君 老師', 'color': const Color(0xFF60A5FA)},
            {'subject': '美語', 'name': '陳怡君 老師', 'color': const Color(0xFFFBBF24)},
            {'subject': '國文', 'name': '林怡君 老師', 'color': const Color(0xFF60A5FA)},
            {'subject': '作文', 'name': '黃怡君 老師', 'color': const Color(0xFFFBBF24)},
          ],
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildStudentCard({
    required String name,
    required String schoolInfo,
    required List<Map<String, dynamic>> teachers,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54.w,
                        height: 54.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        name,
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '| $schoolInfo',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF0F2F5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.edit, size: 14.sp, color: const Color(0xFF757575)),
                    ),
                    SizedBox(height: 12.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: teachers.map((item) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8.w,
                                height: 8.w,
                                color: item['color'] as Color,
                              ),
                              SizedBox(width: 6.w),
                              Text(
                                '${item['subject']} ${item['name']}',
                                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF616161)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 7,
                child: Container(height: 4.h, color: const Color(0xFF60A5FA)),
              ),
              Expanded(
                flex: 4,
                child: Container(height: 4.h, color: const Color(0xFFFBBF24)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: const Color(0xFF1E1E1E)),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFB0B0B0), width: 0.8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscureText : false,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 14.sp),
        keyboardType: TextInputType.visiblePassword,
        autocorrect: false,
        enableSuggestions: false,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
        ],
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF757575),
              size: 20.sp,
            ),
            splashRadius: 18.r,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onToggleVisibility,
          )
              : null,
          suffixIconConstraints: BoxConstraints(
            minWidth: 40.w,
            minHeight: 48.h,
          ),
        ),
      ),
    );
  }
}