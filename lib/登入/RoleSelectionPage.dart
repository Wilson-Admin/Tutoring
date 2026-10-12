import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../家長/parent_home_page.dart';
import '../老師/teacher_home_page.dart';
import '../資料結構/Structures.dart';

class RoleSelectionPage extends StatelessWidget {
  final LoginData? loginData;

  const RoleSelectionPage({super.key, this.loginData});

  Future<void> _selectRole(BuildContext context, {required bool isParent}) async {
    final prefs = await SharedPreferences.getInstance();

    if (isParent) {
      // 從登入者 schools 中找出家長身分 (roleCode 為 'P') 的分校資訊
      final parentSchool = loginData?.schools.firstWhere(
            (s) => s.roleCode.toUpperCase() == 'P',
        orElse: () => loginData!.schools.first,
      );

      final roleCode = parentSchool?.roleCode ?? 'P';
      await prefs.setString('role_code', roleCode);

      if (parentSchool != null) {
        await prefs.setString('depm_no', parentSchool.depmNo);
        await prefs.setString('depm_nm', parentSchool.depmNm);
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ParentHomePage(
              userName: loginData?.userNm ?? '',
            ),
          ),
        );
      }
    } else {
      // 從登入者 schools 中找出教職員身分 (roleCode 非 'P') 的分校資訊，動態取得其 roleCode
      final staffSchool = loginData?.schools.firstWhere(
            (s) => s.roleCode.toUpperCase() != 'P',
        orElse: () => loginData!.schools.first,
      );

      // 依據登入者實際所屬學校的 roleCode 填入 (例如登入者資料中的 'T' 或 'M')
      final roleCode = staffSchool?.roleCode ?? 'T';
      await prefs.setString('role_code', roleCode);

      if (staffSchool != null) {
        await prefs.setString('depm_no', staffSchool.depmNo);
        await prefs.setString('depm_nm', staffSchool.depmNm);
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TeacherHomePage(
              userName: loginData?.userNm ?? '',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: 50.h),
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
                                  'DOLPHIN\nLOGO',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF1976D2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 36.h),
                          Text(
                            '請問您的身分是',
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          SizedBox(height: 40.h),
                          // 家長按鈕
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B4D9B),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              onPressed: () => _selectRole(context, isParent: true),
                              child: Text(
                                '家長',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          // 教師按鈕：根據登入者資料中的 roleCode 動態填入
                          SizedBox(
                            width: double.infinity,
                            height: 54.h,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3880F5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                              ),
                              onPressed: () => _selectRole(context, isParent: false),
                              child: Text(
                                '教師',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}