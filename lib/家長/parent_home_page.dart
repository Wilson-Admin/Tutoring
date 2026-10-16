import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/ChatListResponse.dart';
import '../資料結構/Structures.dart';
import '../資料結構/StudentListResponse.dart';
import 'parent_chat_page.dart';
import 'parent_notification_page.dart';
import 'parent_settings_page.dart';

class ParentHomePage extends StatefulWidget {
  final String userName;

  const ParentHomePage({super.key, required this.userName});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  int _currentIndex = 2; // 預設 2: 學生管理首頁[cite: 24]
  List<StudentItem> _students = [];
  int _selectedStudentIndex = 0;
  bool _isLoadingStudents = false;
  int _unreadChatTotal = 0; // 👈 儲存未讀聊天室訊息總數 (unreadTotal)

  final List<Map<String, Color>> _pillColors = [
    {'bg': const Color(0xFF7079FB), 'text': Colors.white},
    {'bg': const Color(0xFFDDF5EB), 'text': const Color(0xFF00875A)},
    {'bg': const Color(0xFFFEF2D6), 'text': const Color(0xFFC78300)},
    {'bg': const Color(0xFFFFECEE), 'text': const Color(0xFFFF5A60)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// 同時載入學生列表與聊天室未讀總數
  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchStudents(),
      _fetchChatUnreadTotal(),
    ]);
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoadingStudents = true);
    final prefs = await SharedPreferences.getInstance();
    final userNo = prefs.getString('user_no') ?? '';
    final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
    final roleCode = prefs.getString('role_code') ?? 'P';

    final res = await AuthService.getStudents(
      userNo: userNo,
      xApiKey: xApiKey,
      roleCode: roleCode,
    );

    if (mounted) {
      setState(() {
        _isLoadingStudents = false;
        if (res.success && res.data != null) {
          _students = res.data!.items;
        }
      });
    }
  }

  /// 呼叫聊天室 API 取得 unreadTotal
  Future<void> _fetchChatUnreadTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

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
      debugPrint('[Home] 取得聊天室未讀數量異常: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF9FAFC),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: [
                    const ParentNotificationPage(),
                    ParentChatPage(
                      onUnreadChanged: (total) {
                        setState(() {
                          _unreadChatTotal = total;
                        });
                      },
                    ),
                    _buildHomeDashboard(),
                    const Center(child: Text('學習中心頁面')),
                    const ParentSettingsPage(),
                  ],
                ),
              ),
              _buildBottomNav(activeIndex: _currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeDashboard() {
    final currentStudentName = _students.isNotEmpty && _selectedStudentIndex < _students.length
        ? _students[_selectedStudentIndex].csNm
        : '';

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                '${widget.userName}，早安',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              SizedBox(width: 6.w),
              Text('☀️', style: TextStyle(fontSize: 20.sp)),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildStatusBadge(
                icon: Icons.check_box,
                text: currentStudentName.isNotEmpty ? '$currentStudentName · 今日到校' : '今日到校',
                bgColor: const Color(0xFFD8F3E5),
                textColor: const Color(0xFF00875A),
                iconColor: const Color(0xFF00A36C),
              ),
              SizedBox(width: 8.w),
              _buildStatusBadge(
                icon: Icons.assignment_outlined,
                text: '作業未繳 1',
                bgColor: const Color(0xFFFFF3D6),
                textColor: const Color(0xFF9E6B00),
                iconColor: const Color(0xFFE5A100),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 學生切換膠囊列表
          if (_isLoadingStudents)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
            )
          else if (_students.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_students.length, (index) {
                  final student = _students[index];
                  final isSelected = _selectedStudentIndex == index;
                  final colorTheme = _pillColors[index % _pillColors.length];

                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStudentIndex = index;
                        });
                      },
                      child: _buildStudentPill(
                        student.csNm,
                        isSelected: isSelected,
                        bgColor: isSelected ? const Color(0xFF7079FB) : colorTheme['bg']!,
                        textColor: isSelected ? Colors.white : colorTheme['text']!,
                      ),
                    ),
                  );
                }),
              ),
            ),
          SizedBox(height: 22.h),

          // 最新公告
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('最新公告', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
              Row(
                children: [
                  Text('全部', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B46C1), fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_forward, size: 14.sp, color: const Color(0xFF6B46C1)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 140.w,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildNoticeCard(
                  isGradient: true,
                  badge: '重要',
                  title: '暑期課程報名開始',
                  date: '05/28',
                  icon: '📢',
                ),
                SizedBox(width: 12.w),
                _buildNoticeCard(
                  isGradient: false,
                  title: '6月份月考時間公告',
                  date: '06/20',
                  icon: '📝',
                ),
              ],
            ),
          ),
          SizedBox(height: 22.h),

          // 今日課程
          Text('今日課程', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
          SizedBox(height: 12.h),
          _buildCourseCard(time: '16:00', title: '數學', timeBgColor: const Color(0xFFF0F3FA), timeColor: const Color(0xFF7B8DB0)),
          SizedBox(height: 10.h),
          _buildCourseCard(
            time: '17:00',
            title: '作文',
            timeBgColor: const Color(0xFFE3F7EE),
            timeColor: const Color(0xFF00A36C),
            isHighlight: true,
            statusBadge: '上課中',
          ),
          SizedBox(height: 10.h),
          _buildCourseCard(time: '18:00', title: '英文', timeBgColor: const Color(0xFFFFF4DF), timeColor: const Color(0xFFF5A623)),
          SizedBox(height: 10.h),
          _buildCourseCard(time: '18:30', title: '課輔', timeBgColor: const Color(0xFFFFECEE), timeColor: const Color(0xFFFF5A60)),
          SizedBox(height: 22.h),

          // 快速功能
          Text('快速功能', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction('聯絡簿', Icons.menu_book, const Color(0xFFEDF5FF), const Color(0xFF3282B8)),
              _buildQuickAction('Go home', Icons.location_on_outlined, const Color(0xFFFFEFEF), const Color(0xFFE55353)),
              _buildQuickAction('課表', Icons.assignment_outlined, const Color(0xFFF3EFFF), const Color(0xFF8C52FF)),
              _buildQuickAction('繳費', Icons.account_balance_wallet_outlined, const Color(0xFFFFF7E6), const Color(0xFFE69A00)),
            ],
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String text, required Color bgColor, required Color textColor, required Color iconColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: iconColor),
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStudentPill(String name, {required bool isSelected, required Color bgColor, required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.r)),
      child: Text(name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: textColor)),
    );
  }

  Widget _buildNoticeCard({
    required bool isGradient,
    String? badge,
    required String title,
    required String date,
    required String icon,
  }) {
    return Container(
      width: 148.w,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: isGradient
            ? const LinearGradient(
          colors: [Color(0xFF6B7BFD), Color(0xFF3F63F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        color: isGradient ? null : const Color(0xFFCCE4FF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 20.sp)),
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.25,
                  color: isGradient ? Colors.white : const Color(0xFF1E1E1E),
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                date,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isGradient ? Colors.white70 : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard({
    required String time,
    required String title,
    required Color timeBgColor,
    required Color timeColor,
    bool isHighlight = false,
    String? statusBadge,
  }) {
    return Container(
      width: double.infinity,
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
          Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
          const Spacer(),
          if (statusBadge != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(12.r)),
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 12.sp, color: Colors.white),
                  SizedBox(width: 2.w),
                  Text(statusBadge, style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
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

    // 將未讀聊天室數量轉為文字（大於 99 顯示 99+，為 0 則不顯示）
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
            '聊天室',
            1,
            badge: chatBadgeText, // 👈 動態綁定 API 回傳的 unreadTotal
            isActive: activeIndex == 1,
          ),
          _buildNavItem(Icons.school, '學生管理', 2, isActive: activeIndex == 2),
          _buildNavItem(Icons.menu_book, '學習中心', 3, isActive: activeIndex == 3),
          _buildNavItem(Icons.settings_outlined, '設定', 4, isActive: activeIndex == 4),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index, {bool isActive = false, String? badge}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
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