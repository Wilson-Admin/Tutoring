import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../共用函式/CurvedNavigationBar/curved_navigation_bar.dart';
import 'teacher_contact_interaction_page.dart';
import 'teacher_notification_page.dart';
import 'teacher_settings_page.dart';

class TeacherHomePage extends StatefulWidget {
  final String userName;

  const TeacherHomePage({super.key, required this.userName});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

// 記得 import 您的 CurvedNavigationBar 檔案，例如：
// import 'curved_navigation_bar.dart';

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _currentIndex = 0; // 預設選中 2: 學生管理 (首頁)[cite: 9]
  int _unreadChatTotal = 0; // 儲存聯絡互動未讀總數[cite: 9]

  @override
  void initState() {
    super.initState();
    _fetchChatUnreadTotal();
  }

  /// 呼叫聊天室 API 取得未讀訊息總數[cite: 9]
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
    // 將未讀總數轉為文字[cite: 9]
    final chatBadgeText = _unreadChatTotal > 0
        ? (_unreadChatTotal > 99 ? '99+' : _unreadChatTotal.toString())
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFC),
        resizeToAvoidBottomInset: false, // 鍵盤彈出時不改變 Scaffold 尺寸[cite: 9]

        // 使用 CurvedNavigationBar 作為底部導航列[cite: 5]
        bottomNavigationBar: CurvedNavigationBar(
          index: _currentIndex,
          // 注意：套件源碼限制 height 最大值為 75.0[cite: 5]
          height: 65.0,
          // backgroundColor 必須與 Scaffold 相同，凹槽處才會完美融合[cite: 5]
          backgroundColor: const Color(0xFFF9FAFC),
          // 導航列主體的深色[cite: 5]
          color: const Color(0xFF1B2B48),
          // 懸浮圓圈的亮藍色[cite: 5]
          buttonBackgroundColor: const Color(0xFF81D4FA),
          // 套用絲滑動畫曲線與時間[cite: 5]
          animationCurve: Curves.fastOutSlowIn,
          animationDuration: const Duration(milliseconds: 350),
          onTap: (index) {
            setState(() {
              _currentIndex = index; // 點選切換畫面[cite: 9]
            });
          },
          items: [
            _buildBadgeIcon('assets/webp/8.webp', null, 0),
            _buildBadgeIcon('assets/webp/7.webp', '3', 1),
            _buildBadgeIcon('assets/webp/6.webp', null, 2),
            _buildBadgeIcon('assets/webp/5.webp', chatBadgeText, 3),
            _buildBadgeIcon('assets/webp/4.webp', null, 4),
          ],
        ),

        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeDashboard(), //
              const TeacherNotificationPage(),
              Container(),
              TeacherContactInteractionPage(
                onUnreadChanged: (total) {
                  setState(() {
                    _unreadChatTotal = total;
                  });
                },
              ), //
              Container()
            ],
          ),
        ),
      ),
    );
  }

  /// 處理圖標與未讀紅點 (配合 CurvedNavigationBar 使用)
  /// [iconOrAsset] 可以傳入 IconData 或 String(Asset 路徑)
  Widget _buildBadgeIcon(dynamic iconOrAsset, String? badge, int itemIndex) {
    final bool isActive = _currentIndex == itemIndex;

    // 決定圖標顏色
    final Color iconColor = isActive ? Colors.white : const Color(0xFF81D4FA);

    // 建立內部的圖標 Widget
    Widget iconWidget;
    if (iconOrAsset is IconData) {
      // 處理內建 IconData
      iconWidget = Icon(
        iconOrAsset,
        size: 22.sp,
        color: iconColor,
      );
    } else if (iconOrAsset is String) {
      // 處理自訂圖片路徑
      iconWidget = Image.asset(
        iconOrAsset,
        width: 22.sp,
        height: 22.sp,
        color: iconColor, // 👈 讓圖片也能配合選中狀態變色 (圖片需為帶有透明背景的單色圖)
        fit: BoxFit.contain,
      );
    } else {
      // 例外情況的預設圖標
      iconWidget = Icon(Icons.error, size: 22.sp, color: iconColor);
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        iconWidget,
        if (badge != null)
          Positioned(
            right: -6.w,
            top: -6.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4D4F),
                borderRadius: BorderRadius.circular(10.r),
              ),
              constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // 下方保留您原本的 Dashboard 內部 UI 程式碼不變
  // ==========================================

  Widget _buildHomeDashboard() {
    // ... [保留原本內容][cite: 9]
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
                  Row(children: [
                    Text(
                      '${widget.userName}，早安',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    Expanded(child: Container()),
                    GestureDetector(
                        onTap: (){
                          // 使用 Navigator.push 跳轉至 TeacherSettingsPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TeacherSettingsPage(),
                            ),
                          );
                        },
                        child: Icon(Icons.settings,size: 26.w,))
                  ],),
                  
                  SizedBox(height: 14.h),
                  // 頂部統計指標[cite: 9]
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
                  // 今日課表與星期切換[cite: 9]
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
                  // 課堂列表[cite: 9]
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
                  // 打卡浮動按鈕區塊[cite: 9]
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
                  // 快速功能[cite: 9]
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
    return Expanded( //[cite: 9]
      // ...保留原內容
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
    return Container( //[cite: 9]
      // ...保留原內容
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
    return Container( //[cite: 9]
      // ...保留原內容
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
    return Container( //[cite: 9]
      // ...保留原內容
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
    return Column( //[cite: 9]
      // ...保留原內容
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
}