import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import 'teacher_contact_interaction_page.dart';
import 'teacher_notification_page.dart';
import 'teacher_settings_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String userName;

  const TeacherHomePage({super.key, required this.userName});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentIndex = 2; // 預設選中 2: 學生管理 (首頁)[cite: 26]
  int _unreadChatTotal = 0; // 👈 儲存聯絡互動未讀總數 (unreadTotal)

  @override
  void initState() {
    super.initState();
    _fetchChatUnreadTotal();
  }

  /// 呼叫聊天室 API 取得未讀訊息總數
  Future<void> _fetchChatUnreadTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'T';

      final res = await AuthService.getChats(
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (mounted && res.success && res.data != null) {
        setState(() {
          _unreadChatTotal = res.data!.unreadTotal;
        });
      }
    } catch (e) {
      debugPrint('[TeacherHome] 取得聯絡互動未讀數量異常: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        resizeToAvoidBottomInset: false, // 👈 鍵盤彈出時不改變 Scaffold 尺寸[cite: 26]
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const TeacherNotificationPage(), // index 0: 通知中心介面[cite: 26]
                    TeacherContactInteractionPage(
                      onUnreadChanged: (total) {
                        setState(() {
                          _unreadChatTotal = total;
                        });
                      },
                    ), // index 1: 聯絡互動[cite: 26]
                    _buildHomeDashboard(), // index 2: 學生管理 / 儀表板首頁[cite: 26]
                    const Center(child: Text('教學管理頁面')), // index 3[cite: 26]
                    const TeacherSettingsPage(), // index 4: 設定頁[cite: 26]
                  ],
                ),
              ),
              // 底部常駐導航列[cite: 26]
              _buildBottomNav(activeIndex: _currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  /// 首頁原本的儀表板內容（滿版適配）[cite: 26]
  Widget _buildHomeDashboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  Text(
                    '${widget.userName}，早安',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  SizedBox(height: 14.h),
                  // 頂部統計指標[cite: 26]
                  Row(
                    children: [
                      _buildStatBox(count: '4', label: '今日課堂', bgColor: const Color(0xFFEBEBFF), accentColor: const Color(0xFF5352ED)),
                      SizedBox(width: 8.w),
                      _buildStatBox(count: '28', label: '今日到校', bgColor: const Color(0xFFD8F6E8), accentColor: const Color(0xFF00BA88)),
                      SizedBox(width: 8.w),
                      _buildStatBox(count: '5', label: '未讀通知', bgColor: const Color(0xFFFFE6E7), accentColor: const Color(0xFFFF4D4F)),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  // 今日課表與星期切換[cite: 26]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('今日課表', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
                      Row(
                        children: [
                          _buildDayCircle('一'),
                          _buildDayCircle('二'),
                          _buildDayCircle('三'),
                          _buildDayCircle('四'),
                          _buildDayCircle('五', isSelected: true),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // 課堂列表[cite: 26]
                  _buildTeacherCourseCard(
                    time: '16:00',
                    title: '數學',
                    subtitle: 'A101 · 32 人',
                    timeBgColor: const Color(0xFFF0F3FA),
                    timeColor: const Color(0xFF7B8DB0),
                    trailingWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('30/32', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF00BA88))),
                        Text('到席', style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E))),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildTeacherCourseCard(
                    time: '17:00',
                    title: '英文',
                    subtitle: 'B205 · 20 人',
                    timeBgColor: const Color(0xFFE3F7EE),
                    timeColor: const Color(0xFF00A36C),
                    isHighlight: true,
                    trailingWidget: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(12.r)),
                      child: Row(
                        children: [
                          Icon(Icons.play_arrow, size: 12.sp, color: Colors.white),
                          SizedBox(width: 2.w),
                          Text('上課中', style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildTeacherCourseCard(
                    time: '18:00',
                    title: 'ESL',
                    subtitle: 'C302 · 14人',
                    timeBgColor: const Color(0xFFFFF4DF),
                    timeColor: const Color(0xFFF5A623),
                    trailingWidget: _buildActionTag('點名', const Color(0xFFFFF4DF), const Color(0xFFF5A623)),
                  ),
                  SizedBox(height: 10.h),
                  _buildTeacherCourseCard(
                    time: '18:30',
                    title: '課輔',
                    subtitle: '· 28 人',
                    timeBgColor: const Color(0xFFFFECEE),
                    timeColor: const Color(0xFFFF5A60),
                    trailingWidget: _buildActionTag('點名', const Color(0xFFFFECEE), const Color(0xFFFF5A60)),
                  ),
                  SizedBox(height: 24.h),
                  // 打卡浮動按鈕區塊[cite: 26]
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                                child: Text('上下班打卡', style: TextStyle(fontSize: 12.sp, color: const Color(0xFF616161), fontWeight: FontWeight.w500)),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B2B48),
                                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.r)),
                                ),
                                child: Text('查詢出勤紀錄', style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          width: 48.w,
                          height: 48.w,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Icon(Icons.add, color: Colors.white, size: 28.sp),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  // 快速功能[cite: 26]
                  Text('快速功能', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickAction('聯絡簿', Icons.menu_book, const Color(0xFFF0EFFF), const Color(0xFF6C63FF)),
                      _buildQuickAction('課程點名', Icons.person_search, const Color(0xFFE8F6FF), const Color(0xFF1890FF)),
                      _buildQuickAction('接送通知', Icons.directions_car_filled, const Color(0xFFFFEEEE), const Color(0xFFFF4D4F)),
                      _buildQuickAction('照片輸入', Icons.photo_library, const Color(0xFFFFF7E6), const Color(0xFFFA8C16)),
                    ],
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatBox({required String count, required String label, required Color bgColor, required Color accentColor}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w900, color: accentColor)),
            SizedBox(width: 4.w),
            Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: accentColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCircle(String day, {bool isSelected = false}) {
    return Container(
      margin: EdgeInsets.only(left: 4.w),
      width: 26.w,
      height: 26.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
        shape: BoxShape.circle,
        border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Text(
        day,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }

  Widget _buildTeacherCourseCard({
    required String time,
    required String title,
    required String subtitle,
    required Color timeBgColor,
    required Color timeColor,
    required Widget trailingWidget,
    bool isHighlight = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isHighlight ? Border.all(color: const Color(0xFF00B074), width: 1.5) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(color: timeBgColor, borderRadius: BorderRadius.circular(14.r)),
            child: Text(time, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: timeColor)),
          ),
          SizedBox(width: 14.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
              SizedBox(height: 2.h),
              Text(subtitle, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
            ],
          ),
          const Spacer(),
          trailingWidget,
        ],
      ),
    );
  }

  Widget _buildActionTag(String label, Color bgColor, Color textColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.edit_note, size: 14.sp, color: textColor),
          SizedBox(width: 2.w),
          Text(label, style: TextStyle(fontSize: 11.sp, color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color bgColor, Color iconColor) {
    return Column(
      children: [
        Container(
          width: 70.w,
          height: 60.h,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14.r)),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        SizedBox(height: 6.h),
        Text(title, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF424242), fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomNav({required int activeIndex}) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // 將未讀總數轉為文字（大於 99 顯示 99+，0 則為 null 不顯示 Badge）
    final chatBadgeText = _unreadChatTotal > 0
        ? (_unreadChatTotal > 99 ? '99+' : _unreadChatTotal.toString())
        : null;

    return Container(
      padding: EdgeInsets.only(
        top: 8.h,
        bottom: bottomPadding > 0 ? bottomPadding : 8.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2B48),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.notifications_none, '通知', 0, badge: '3', isActive: activeIndex == 0),
          _buildNavItem(
            Icons.chat_bubble_outline,
            '聯絡互動',
            1,
            badge: chatBadgeText, // 👈 動態綁定 API 回傳的 unreadTotal
            isActive: activeIndex == 1,
          ),
          _buildNavItem(Icons.group, '學生管理', 2, isActive: activeIndex == 2),
          _buildNavItem(Icons.menu_book, '教學管理', 3, isActive: activeIndex == 3),
          _buildNavItem(Icons.settings_outlined, '設定', 4, isActive: activeIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index, {bool isActive = false, String? badge}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index; // 點選切換畫面[cite: 26]
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22.sp, color: isActive ? const Color(0xFFFFCA28) : Colors.white70),
              SizedBox(height: 4.h),
              Text(title, style: TextStyle(fontSize: 11.sp, color: isActive ? const Color(0xFFFFCA28) : Colors.white70)),
            ],
          ),
          if (badge != null)
            Positioned(
              right: -6,
              top: -3,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D4F),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                child: Text(
                  badge,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}