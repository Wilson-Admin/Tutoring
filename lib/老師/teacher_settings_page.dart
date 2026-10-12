import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutoring/API/auth_service.dart';
import 'package:tutoring/main.dart';

import '../共用函式/app_dialog.dart';
import '../共用函式/app_signature_page.dart';
import '../登入/LoginPage.dart';
import 'teacher_phrases_page.dart';

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

  // 密碼可見性控制
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;

  String _userNm = '';
  String _userNo = '';
  String _roleName = '課輔/英文老師';
  String _schoolName = '';
  String _tel = '';
  String _email = '';
  String _picLink = '';
  String _signLink = ''; // 👈 預設簽名圖片網址
  String _xApiKey = '';
  String _roleCode = 'T';

  File? _localSelectedImage;
  Uint8List? _newSignatureBytes; // 👈 老師本次手寫暫存的簽名 Bytes
  bool _hasNewSignature = false; // 👈 是否有修改簽名標記

  bool _isUploadingPhoto = false;
  bool _isSaving = false;
  bool _isTestingFcm = false;

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
      _signLink = prefs.getString('signLink') ?? prefs.getString('sign_link') ?? '';
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

        AppDialog.show(
          title: '上傳成功',
          message: res['msg']?.toString() ?? '照片更新成功。',
        );
      } else {
        setState(() {
          _localSelectedImage = null;
        });

        final msg = res['msg']?.toString() ?? '';
        final isAuthExpired = msg.contains('X-API-Key') || msg.contains('已過期');
        if (!isAuthExpired) {
          AppDialog.show(
            title: '上傳失敗',
            message: msg.isEmpty ? '上傳失敗，請稍後再試。' : msg,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _localSelectedImage = null;
        });
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

  Future<void> _deletePhoto() async {
    if (_isUploadingPhoto) return;

    final confirm = await AppDialog.showConfirm(
      context: context,
      title: '刪除照片',
      message: '確定要刪除大頭照嗎？',
      confirmText: '確定',
      cancelText: '取消',
    );

    if (!confirm || !mounted) return;

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final res = await AuthService.deletePhoto(
        userNo: _userNo,
        xApiKey: _xApiKey,
        roleCode: _roleCode,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('picLink');

        setState(() {
          _picLink = '';
          _localSelectedImage = null;
        });

        AppDialog.show(
          title: '提示',
          message: res['msg']?.toString() ?? '照片刪除成功。',
        );
      } else {
        final msg = res['msg']?.toString() ?? '';
        final isAuthExpired = msg.contains('X-API-Key') || msg.contains('已過期');
        if (!isAuthExpired) {
          AppDialog.show(
            title: '刪除失敗',
            message: msg.isEmpty ? '刪除失敗，請稍後再試。' : msg,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          title: '異常',
          message: '刪除大頭照發生異常: $e',
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

  /// 跳轉至橫向手寫簽名頁
  /// 跳轉至橫向手寫簽名頁
  Future<void> _openSignaturePage() async {
    final Uint8List? signatureResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AppSignaturePage(title: '老師簽名'), // 👈 改呼共用並指定老師標題
      ),
    );

    if (signatureResult != null && signatureResult.isNotEmpty) {
      setState(() {
        _newSignatureBytes = signatureResult;
        _hasNewSignature = true;
      });
    }
  }

  /// 測試推播：呼叫 Google FCM HTTP v1 API 真正發送推播給自己
  Future<void> _handleTestFcm() async {
    if (_isTestingFcm) return;

    setState(() {
      _isTestingFcm = true;
    });

    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('fcm_token');
      }

      if (token == null || token.isEmpty) {
        AppDialog.show(
          title: '提示',
          message: '尚未取得本機 FCM Token，請確認通知權限或稍後再試。',
        );
        return;
      }

      await Clipboard.setData(ClipboardData(text: token));

      final res = await AuthService.sendGoogleFcmNotification(
        fcmToken: token,
        title: '補習班測試通知',
        body: '這是一則直接呼叫 Google FCM HTTP v1 API 發送的推播！',
      );

      if (!mounted) return;

      if (res['success'] == true) {
        AppDialog.show(
          title: '推播已送出',
          message: '已成功向 Google FCM 伺服器提交請求！請將 App 切換至後台或查看頂部狀態列。',
        );
      } else {
        AppDialog.show(
          title: '發送失敗',
          message: 'Google 回傳錯誤：${res['msg']}',
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          title: '異常',
          message: '測試過程發生錯誤：$e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTestingFcm = false;
        });
      }
    }
  }

  /// 儲存設定（包含：上傳更新簽名、FCM Token 更新與變更密碼）
  Future<void> _handleSaveSettings() async {
    if (_isSaving) return;

    final account = _accountController.text.trim();
    final oldPassword = _passwordController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final alphaNumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

    if (account.isNotEmpty && !alphaNumericRegex.hasMatch(account)) {
      AppDialog.show(
        title: '格式錯誤',
        message: '帳號(行動電話)僅接受英文字母及數字。',
      );
      return;
    }

    final bool hasPasswordChange = oldPassword.isNotEmpty || newPassword.isNotEmpty;

    if (hasPasswordChange) {
      if (oldPassword.isEmpty) {
        AppDialog.show(
          title: '請輸入密碼',
          message: '變更密碼時，請輸入目前密碼。',
        );
        return;
      }

      if (newPassword.isEmpty) {
        AppDialog.show(
          title: '請輸入新密碼',
          message: '請輸入欲變更的新密碼。',
        );
        return;
      }

      if (!alphaNumericRegex.hasMatch(oldPassword) || !alphaNumericRegex.hasMatch(newPassword)) {
        AppDialog.show(
          title: '格式錯誤',
          message: '密碼僅接受英文字母及數字。',
        );
        return;
      }

      if (newPassword == oldPassword) {
        AppDialog.show(
          title: '提示',
          message: '新密碼不可與目前密碼相同。',
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. 若有手寫新簽名，呼叫簽名上傳 API
      if (_hasNewSignature && _newSignatureBytes != null) {
        final signRes = await AuthService.uploadSignature(
          imageBytes: _newSignatureBytes!,
          userNo: _userNo,
          xApiKey: _xApiKey,
          roleCode: _roleCode,
        );

        if (signRes['success'] == true) {
          final data = signRes['data'];
          final uploadedSignLink = (data is Map ? data['picLink'] : null)?.toString() ?? '';
          if (uploadedSignLink.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('signLink', uploadedSignLink);
            setState(() {
              _signLink = uploadedSignLink;
              _hasNewSignature = false;
            });
          }
        } else {
          final msg = signRes['msg']?.toString() ?? '簽名更新失敗';
          final isAuthExpired = msg.contains('X-API-Key') || msg.contains('已過期');
          if (!isAuthExpired) {
            AppDialog.show(title: '簽名儲存失敗', message: msg);
          }
          return;
        }
      }

      // 2. 同步更新 FCM Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('[FCM] 取得 Token 失敗: $e');
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final fcmRes = await AuthService.updateFcmToken(
          fcmToken: fcmToken,
          userNo: _userNo,
          xApiKey: _xApiKey,
          roleCode: _roleCode,
        );

        if (fcmRes['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('fcm_token', fcmToken);
        }
      }

      if (!mounted) return;

      // 3. 處理變更密碼
      if (hasPasswordChange) {
        final res = await AuthService.changePassword(
          userNo: _userNo,
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmPassword: newPassword,
          xApiKey: _xApiKey,
          roleCode: _roleCode,
        );

        if (!mounted) return;

        if (res['success'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.remove('user_token');
          await prefs.setBool('is_logged_in', false);
          await prefs.remove('is_logged_in');
          await prefs.remove('xApiKey');
          await prefs.remove('x_api_key');

          await AppDialog.show(
            title: '密碼變更成功',
            message: res['msg']?.toString() ?? '密碼變更成功，請使用新密碼重新登入。',
          );

          if (!mounted) return;

          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
          RestartWidget.restartApp(context);
          return;
        } else {
          final msg = res['msg']?.toString() ?? '';
          final isAuthExpired = msg.contains('X-API-Key') || msg.contains('已過期');
          if (!isAuthExpired) {
            AppDialog.show(
              title: '變更失敗',
              message: msg.isEmpty ? '密碼變更失敗，請確認目前密碼是否正確。' : msg,
            );
          }
          return;
        }
      }

      AppDialog.show(
        title: '提示',
        message: '設定已成功儲存',
      );
    } catch (e) {
      if (mounted) {
        AppDialog.show(
          title: '異常',
          message: '儲存設定連線異常: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
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
    final formattedUrl = _formatImageUrl(_picLink);
    final formattedSignUrl = _formatImageUrl(_signLink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionHeader('帳號'),
        SizedBox(height: 8.h),
        _buildInputField(controller: _accountController),
        SizedBox(height: 20.h),
        _buildSectionHeader('密碼'),
        SizedBox(height: 8.h),
        _buildInputField(
          controller: _passwordController,
          isPassword: true,
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        SizedBox(height: 20.h),
        _buildSectionHeader('修改密碼'),
        SizedBox(height: 8.h),
        _buildInputField(
          controller: _newPasswordController,
          isPassword: true,
          obscureText: _obscureNewPassword,
          onToggleVisibility: () {
            setState(() {
              _obscureNewPassword = !_obscureNewPassword;
            });
          },
        ),
        SizedBox(height: 20.h),

        // ─── 預設簽名區塊 ───
        _buildSectionHeader('預設簽名'),
        SizedBox(height: 8.h),
        Container(
          height: 140.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: const Color(0xFFB0B0B0), width: 1.0),
          ),
          clipBehavior: Clip.antiAlias,
          child: _newSignatureBytes != null
              ? Image.memory(
            _newSignatureBytes!,
            fit: BoxFit.contain,
          )
              : (formattedSignUrl.isNotEmpty
              ? Image.network(
            formattedSignUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Text(
                '尚未設定簽名',
                style: TextStyle(color: Color(0xFFBDBDBD)),
              ),
            ),
          )
              : const Center(
            child: Text(
              '尚未設定簽名',
              style: TextStyle(color: Color(0xFFBDBDBD)),
            ),
          )),
        ),
        SizedBox(height: 10.h),
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: _openSignaturePage,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                borderRadius: BorderRadius.circular(18.r),
              ),
              child: Text(
                '修改簽名',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeacherPhrasesPage()),
            );
          },
          child: Container(
            width: double.infinity,
            height: 50.h,
            decoration: BoxDecoration(
              color: const Color(0xFFD4D2FE), // 👈 與設計圖一致的淡紫色底
              borderRadius: BorderRadius.circular(16.r),
            ),
            alignment: Alignment.center,
            child: Text(
              '聯絡簿/作業 常用片語',
              style: TextStyle(
                color: const Color(0xFF6C63FF),
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),

        // 預設大頭照標題
        Text(
          '預設大頭照',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        SizedBox(height: 18.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showImagePickerModal,
              child: Container(
                width: 100.w,
                height: 100.w,
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
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.add,
                          size: 48.sp,
                          color: Colors.white,
                        ),
                      )
                    else
                      Icon(
                        Icons.add,
                        size: 48.sp,
                        color: Colors.white,
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
            SizedBox(width: 24.w),
            Container(
              width: 120.w,
              height: 94.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: const Color(0xFFB0B0B0), width: 1.0),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Expanded(
                    child: Material(
                      color: const Color(0xFF1B2D4A),
                      child: InkWell(
                        onTap: _showImagePickerModal,
                        child: Center(
                          child: Text(
                            '更換照片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Material(
                      color: const Color(0xFFBDBDBD),
                      child: InkWell(
                        onTap: _deletePhoto,
                        child: Center(
                          child: Text(
                            '刪除照片',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 32.h),

        // 測試推播按鈕
        OutlinedButton.icon(
          onPressed: _isTestingFcm ? null : _handleTestFcm,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF4B39EF), width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 13.h),
          ),
          icon: _isTestingFcm
              ? SizedBox(
            width: 18.w,
            height: 18.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF4B39EF),
            ),
          )
              : Icon(
            Icons.send_rounded,
            color: const Color(0xFF4B39EF),
            size: 20.sp,
          ),
          label: Text(
            _isTestingFcm ? '發送推播中…' : '發送 Google 官方測試推播',
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF4B39EF),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 14.h),

        // 儲存設定按鈕
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSaveSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 14.h),
          ),
          child: _isSaving
              ? SizedBox(
            width: 24.w,
            height: 24.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
              : Text(
            '儲存',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // 登出按鈕
        Center(
          child: TextButton(
            onPressed: _handleLogout,
            child: Text(
              '登出',
              style: TextStyle(
                fontSize: 18.sp,
                color: Colors.black,
                fontWeight: FontWeight.w900,
              ),
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
                        Container(
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
                        )
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

  Widget _buildInputField({
    required TextEditingController controller,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
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
          obscureText: isPassword ? obscureText : false,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF757575),
                size: 20.sp,
              ),
              splashRadius: 20.r,
              onPressed: onToggleVisibility,
            )
                : null,
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