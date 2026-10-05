import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutoring/API/auth_service.dart';
import 'package:tutoring/main.dart';

import '../共用函式/app_dialog.dart';
import '../登入/LoginPage.dart';

class TeacherSettingsPage extends StatefulWidget {
  const TeacherSettingsPage({super.key});

  @override
  State<TeacherSettingsPage> createState() => _TeacherSettingsPageState();
}

class _TeacherSettingsPageState extends State<TeacherSettingsPage> {
  int _tabIndex = 0; // 0: 帳號相關, 1: 個人資訊
  final TextEditingController _customPhraseController = TextEditingController();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  String _userNm = '';
  String _userNo = '';
  String _roleName = '課輔/英文老師';
  String _schoolName = '';
  String _tel = '';
  String _email = '';
  String _picLink = '';
  String _xApiKey = '';
  String _roleCode = 'T';

  File? _localSelectedImage;
  bool _isUploadingPhoto = false;

  final ImagePicker _picker = ImagePicker();

  final List<String> _phrases = [
    '國文講義作業:',
    '明天校外教學，請協助寶貝們不要忘記帶水',
    '請家長協助簽名後帶回',
    '請複習今天教的單字。',
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherInfo();
  }

  Future<void> _loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userNo = prefs.getString('user_no') ?? prefs.getString('saved_user_phone') ?? '';
      _userNm = prefs.getString('user_nm') ?? '';
      _picLink = prefs.getString('picLink') ?? '';
      _schoolName = prefs.getString('school_name') ?? prefs.getString('school_nm') ?? '';
      _tel = prefs.getString('tel') ?? prefs.getString('phone') ?? '';
      _email = prefs.getString('email') ?? '';
      _xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      _roleCode = prefs.getString('role_code') ?? 'T';

      _accountController.text = _userNo;
    });
  }

  String _formatImageUrl(String rawLink) {
    if (rawLink.isEmpty) return '';
    if (rawLink.startsWith('http://') || rawLink.startsWith('https://')) {
      return rawLink;
    }
    if (rawLink.startsWith('~/')) {
      return '${AuthService.baseUrl}/${rawLink.substring(2)}';
    }
    if (rawLink.startsWith('/')) {
      return '${AuthService.baseUrl}$rawLink';
    }
    return '${AuthService.baseUrl}/$rawLink';
  }

  Future<void> _showImagePickerModal() async {
    if (_isUploadingPhoto) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF6C63FF)),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00B074)),
                title: const Text('從相簿選取'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _localSelectedImage = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      final res = await AuthService.uploadPhoto(
        filePath: pickedFile.path,
        userNo: _userNo,
        xApiKey: _xApiKey,
        roleCode: _roleCode,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final data = res['data'];
        final newPicLink = (data is Map ? data['picLink'] : null)?.toString() ?? '';

        final prefs = await SharedPreferences.getInstance();
        if (newPicLink.isNotEmpty) {
          await prefs.setString('picLink', newPicLink);
        }

        setState(() {
          if (newPicLink.isNotEmpty) {
            _picLink = newPicLink;
          }
          _localSelectedImage = null;
        });

        // 成功彈出 Dialog[cite: 14]
        AppDialog.show(
          title: '上傳成功',
          message: res['msg']?.toString() ?? '照片更新成功。',
        );
      } else {
        setState(() {
          _localSelectedImage = null;
        });
        // 失敗彈出 Dialog[cite: 14]
        AppDialog.show(
          title: '上傳失敗',
          message: res['msg']?.toString() ?? '上傳失敗，請稍後再試。',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localSelectedImage = null;
        });
        // 異常彈出 Dialog[cite: 14]
        AppDialog.show(
          title: '上傳異常',
          message: '選取或上傳照片異常: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _customPhraseController.dispose();
    _accountController.dispose();
    _passwordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _addPhrase() {
    final text = _customPhraseController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _phrases.add(text);
        _customPhraseController.clear();
      });
    }
  }

  Future<void> _handleLogout() async {
    // 登出確認對話框使用 AppDialog.showConfirm[cite: 14]
    final shouldLogout = await AppDialog.showConfirm(
      context: context,
      title: '確定登出？',
      message: '登出後將返回登入畫面，已儲存的登入資訊將妥善保留。',
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
      await prefs.setBool('is_logged_in', false); // 👈 確保設為 false
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
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
                              child: _buildTabButton(
                                title: '帳號相關',
                                index: 0,
                                activeColor: const Color(0xFFC7C5FD),
                                activeTextColor: const Color(0xFF4B39EF),
                                inactiveColor: const Color(0xFFDCDAFE),
                                inactiveTextColor: const Color(0xFF6C63FF),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildTabButton(
                                title: '個人資訊',
                                index: 1,
                                activeColor: const Color(0xFF00B074),
                                activeTextColor: Colors.white,
                                inactiveColor: const Color(0xFFD6F5E8),
                                inactiveTextColor: const Color(0xFF00B074),
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
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required int index,
    required Color activeColor,
    required Color activeTextColor,
    required Color inactiveColor,
    required Color inactiveTextColor,
  }) {
    final isSelected = _tabIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() {
            _tabIndex = index;
          });
        },
        child: Ink(
          height: 48.h,
          decoration: BoxDecoration(
            color: isSelected ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? activeTextColor : inactiveTextColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('帳號'),
        SizedBox(height: 8.h),
        _buildInputField(controller: _accountController),
        SizedBox(height: 20.h),
        _buildSectionHeader('密碼'),
        SizedBox(height: 8.h),
        _buildInputField(controller: _passwordController, isPassword: true),
        SizedBox(height: 20.h),
        _buildSectionHeader('修改密碼'),
        SizedBox(height: 8.h),
        _buildInputField(controller: _newPasswordController, isPassword: true),
        SizedBox(height: 24.h),
        _buildSectionHeader('聯絡簿/作業 常用片語'),
        SizedBox(height: 12.h),
        Row(
          children: [
            Text(
              '常用句',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C63FF),
              ),
            ),
            SizedBox(width: 8.w),
            const Expanded(
              child: Divider(color: Color(0xFF8C86FF), thickness: 1),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 46.h,
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: const Color(0xFF8C86FF), width: 1.5),
                ),
                child: TextField(
                  controller: _customPhraseController,
                  style: TextStyle(fontSize: 13.sp),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: '自訂句子後按插入…',
                    hintStyle: TextStyle(
                      color: Color(0xFFBDBDBD),
                      fontSize: 13,
                    ),
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: _addPhrase,
              child: Container(
                height: 46.h,
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAD8DB),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  '插入',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFB0B0B0), width: 0.8),
          ),
          child: Column(
            children: _phrases.map((phrase) {
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2FF),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFFC3C1FF)),
                ),
                child: Text(
                  phrase,
                  style: TextStyle(
                    color: const Color(0xFF424242),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        SizedBox(height: 30.h),
        ElevatedButton(
          onPressed: () {
            // 點擊儲存彈出 Dialog[cite: 14]
            AppDialog.show(
              title: '提示',
              message: '設定已成功儲存',
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9E9BF8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          child: Text(
            '儲存',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        OutlinedButton(
          onPressed: _handleLogout,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 13.h),
          ),
          child: Text(
            '登出',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFFFF5252),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildProfileTab() {
    return Column(
      children: [
        _buildTeacherProfileCard(),
        SizedBox(height: 32.h),
        const Divider(
          color: Color(0xFFBDBDBD),
          thickness: 1.0,
        ),
      ],
    );
  }

  Widget _buildTeacherProfileCard() {
    final displayName = _userNm.isNotEmpty ? '${_userNm}老師' : '陳怡君老師';
    final formattedUrl = _formatImageUrl(_picLink);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF757575), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF1E3A8A), width: 0),
                              color: Colors.white,
                            ),
                            child: Center(
                              child: Image.asset(
                                'assets/webp/3.webp',
                                width: 50.w,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.school,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF212121),
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _roleName,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF757575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _showImagePickerModal,
                          child: Container(
                            width: 26.w,
                            height: 26.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFBDBDBD),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.edit, size: 14.sp, color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        GestureDetector(
                          onTap: _showImagePickerModal,
                          child: Container(
                            width: 72.w,
                            height: 72.w,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD5D5D5),
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (_localSelectedImage != null)
                                  Image.file(
                                    _localSelectedImage!,
                                    fit: BoxFit.cover,
                                  )
                                else if (formattedUrl.isNotEmpty)
                                  Image.network(
                                    formattedUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: const Color(0xFFD5D5D5),
                                      child: Icon(Icons.person, size: 40.sp, color: Colors.white),
                                    ),
                                  )
                                else
                                  Container(
                                    color: const Color(0xFFD5D5D5),
                                    child: Icon(Icons.person, size: 40.sp, color: Colors.white),
                                  ),
                                if (_isUploadingPhoto)
                                  Container(
                                    color: Colors.black.withOpacity(0.4),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24.w,
                                        height: 24.w,
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  height: 1.5.h,
                  width: double.infinity,
                  color: const Color(0xFF90CAF9),
                ),
                SizedBox(height: 14.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem(
                            color: const Color(0xFFE5B839),
                            label: '所屬單位',
                            value: _schoolName,
                          ),
                          SizedBox(height: 8.h),
                          _buildInfoItem(
                            color: const Color(0xFF6BB8FF),
                            label: 'TEL',
                            value: _tel,
                          ),
                          SizedBox(height: 8.h),
                          _buildInfoItem(
                            color: const Color(0xFFE5B839),
                            label: 'E-Mail',
                            value: _email,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem(
                            color: const Color(0xFF6BB8FF),
                            label: '工號',
                            value: _userNo,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 6.h,
            width: double.infinity,
            child: CustomPaint(
              painter: _CardBottomBarPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({required Color color, required String label, String value = ''}) {
    return Row(
      children: [
        Container(
          width: 12.w,
          height: 12.w,
          color: color,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: SizedBox(
            height: 20.h,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value.trim().isEmpty ? label : '$label  $value',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF616161),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1E1E1E),
        ),
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, bool isPassword = false}) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFB0B0B0), width: 0.8),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
          ),
        ),
      ),
    );
  }
}

class _CardBottomBarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const blueColor = Color(0xFF6BB8FF);
    const yellowColor = Color(0xFFE5B839);

    final bluePaint = Paint()..color = blueColor;
    final yellowPaint = Paint()..color = yellowColor;

    final splitX = size.width * 0.55;
    final slantWidth = size.height * 1.5;

    final bluePath = Path()
      ..moveTo(0, 0)
      ..lineTo(splitX + slantWidth, 0)
      ..lineTo(splitX, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    final yellowPath = Path()
      ..moveTo(splitX + slantWidth + 2, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(splitX + 2, size.height)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}