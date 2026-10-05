import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../家長/parent_home_page.dart';
import '../老師/teacher_home_page.dart';
import '../資料結構/Structures.dart';

class RoleSelectionPage extends StatelessWidget {
  final LoginData? loginData;

  const RoleSelectionPage({super.key, this.loginData});

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
                  minHeight: constraints.maxHeight, // 撐滿垂直整個螢幕高度
                  minWidth: constraints.maxWidth,   // 撐滿水平整個螢幕寬度
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 36.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 主要內容區域
                      Column(
                        children: [
                          SizedBox(height: 50.h),
                          // 海豚 Logo 區域
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
                          // 家長按鈕（寬度填滿 double.infinity）
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
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentHomePage(
                                      userName: loginData?.userNm ?? '王媽媽',
                                    ),
                                  ),
                                );
                              },
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
                          // 教師按鈕（寬度填滿 double.infinity）
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
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TeacherHomePage(
                                      userName: loginData?.userNm ?? '王老師',
                                    ),
                                  ),
                                );
                              },
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
                      // 底部留白保險，避免貼齊邊緣
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