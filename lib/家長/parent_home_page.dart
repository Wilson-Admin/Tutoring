import 'dart:async';
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
import '../資料結構/NoticeResponse.dart'; // 新增這行以使用 NoticeItem
// 👉 確保匯入了 CurvedNavigationBar 套件
import '../共用函式/CurvedNavigationBar/curved_navigation_bar.dart';

class ParentHomePage extends StatefulWidget {
  final String userName;

  const ParentHomePage({super.key, required this.userName});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  int _currentIndex = 0; // 預設 2: 學生管理首頁[cite: 13]
  List<StudentItem> _students = [];
  int _selectedStudentIndex = 0;
  bool _isLoadingStudents = false;

  int _unreadChatTotal = 0; // 聊天室未讀總數[cite: 13]
  int _unreadNoticeTotal = 0; // 公告未讀總數[cite: 13]

  List<NoticeItem> _latestNotices = []; // 存放最新3筆公告[cite: 13]

  Timer? _badgeTimer;

  // 👉 建立 GlobalKey 以控制 CurvedNavigationBar[cite: 13]
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  final List _pillColors = [
    {'bg': const Color(0xFF7079FB), 'text': Colors.white},
    {'bg': const Color(0xFFDDF5EB), 'text': const Color(0xFF00875A)},
    {'bg': const Color(0xFFFEF2D6), 'text': const Color(0xFFC78300)},
    {'bg': const Color(0xFFFFECEE), 'text': const Color(0xFFFF5A60)},
  ];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();

    // 每 10 秒自動在背景拉取未讀總數 (包含聊天室與公告)[cite: 13]
    _badgeTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchChatUnreadTotal();
      _fetchNoticeUnreadTotal();
    });
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    super.dispose();
  }

  // 處理公告圖示[cite: 13]
  String _getNoticeIcon(String noticeType) {
    switch (noticeType) {
      case 'S':
        return '🏫';
      case 'A':
        return '🎉';
      case 'M':
        return '⚙️';
      default:
        return '📣';
    }
  }

  // 處理公告時間格式[cite: 13]
  String _formatDateString(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  /// 同時載入學生列表、聊天室未讀總數、公告未讀總數[cite: 13]
  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchStudents(),
      _fetchChatUnreadTotal(),
      _fetchNoticeUnreadTotal(),
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

  /// 呼叫聊天室 API 取得 unreadTotal[cite: 13]
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

  /// 呼叫公告 API 取得未讀/總數量 (背景靜默執行)[cite: 13]
  Future<void> _fetchNoticeUnreadTotal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '0900000001';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      final res = await AuthService.getActiveNotices(
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (mounted && res.success && res.data != null) {
        setState(() {
          _unreadNoticeTotal = res.data!.total;
          _latestNotices = res.data!.items.take(3).toList();
        });
      }
    } catch (e) {
      debugPrint('[Home] 取得公告未讀數量異常: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 取得各頁籤的未讀數量[cite: 13]
    final chatBadgeText = _unreadChatTotal > 0
        ? (_unreadChatTotal > 99 ? '99+' : _unreadChatTotal.toString())
        : null;

    final noticeBadgeText = _unreadNoticeTotal > 0
        ? (_unreadNoticeTotal > 99 ? '99+' : _unreadNoticeTotal.toString())
        : null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false, //[cite: 13]
        backgroundColor: const Color(0xFFF9FAFC),

        // 👉 加入 CurvedNavigationBar 底部導航列
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _currentIndex,
          height: 65.0,
          backgroundColor: const Color(0xFFF9FAFC),
          color: const Color(0xFF1B2B48),
          buttonBackgroundColor: const Color(0xFF81D4FA),
          animationCurve: Curves.fastOutSlowIn,
          animationDuration: const Duration(milliseconds: 350),
          onTap: (index) {
            setState(() {
              _currentIndex = index; // 點選切換畫面[cite: 13]
            });
          },
          items: [
            _buildBadgeIcon('assets/webp/8.webp', null, 0),
            _buildBadgeIcon('assets/webp/7.webp', noticeBadgeText, 1),
            _buildBadgeIcon('assets/webp/10.webp', null, 2),
            _buildBadgeIcon('assets/webp/9.webp', chatBadgeText, 3),
            _buildBadgeIcon('assets/webp/11.webp', null, 4),
          ],
        ),

        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _currentIndex,
            children: [
              _buildHomeDashboard(), // index 2[cite: 13]
              ParentNotificationPage(
                onNoticeCountChanged: (count) {
                  setState(() {
                    _unreadNoticeTotal = count;
                  });
                },
              ), // index 0[cite: 13]
              Container(), // index 4[cite: 13]
              ParentChatPage(
          onUnreadChanged: (total) {
            setState(() {
              _unreadChatTotal = total;
            });
          },
        ), //
              Container(), // index 4[cite: 13]
            ],
          ),
        ),
      ),
    );
  }

  /// 👉 處理圖標與未讀紅點 (配合 CurvedNavigationBar 使用)
  /// [iconOrAsset] 可以傳入 IconData 或 String(Asset 路徑)
  Widget _buildBadgeIcon(dynamic iconOrAsset, String? badge, int itemIndex) {
    final bool isActive = _currentIndex == itemIndex;

    // 決定圖標顏色
    final Color iconColor = isActive ? Colors.white : const Color(0xFF81D4FA);

    // 建立內部的圖標 Widget
    Widget iconWidget;
    if (iconOrAsset is IconData) {
      iconWidget = Icon(
        iconOrAsset,
        size: 22.sp,
        color: iconColor,
      );
    } else if (iconOrAsset is String) {
      iconWidget = Image.asset(
        iconOrAsset,
        width: 22.sp,
        height: 22.sp,
        color: iconColor,
        fit: BoxFit.contain,
      );
    } else {
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

  Widget _buildHomeDashboard() {
    final currentStudentName = _students.isNotEmpty && _selectedStudentIndex < _students.length
        ? _students[_selectedStudentIndex].csNm
        : ''; //[cite: 13]

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(), //[cite: 13]
      padding: EdgeInsets.symmetric(horizontal: 20.w), //[cite: 13]
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                '${widget.userName}，早安', //[cite: 13]
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900, //[cite: 13]
                  color: const Color(0xFF1E1E1E),
                ),
              ),
              SizedBox(width: 6.w),
              Text('☀️', style: TextStyle(fontSize: 20.sp)), //[cite: 13]
              Expanded(child: Container()),
              // 👉 設定按鈕：使用 Navigator 跳轉至設定頁
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ParentSettingsPage(),
                    ),
                  );
                },
                child: Icon(
                  Icons.settings,
                  size: 26.w,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _buildStatusBadge(
                icon: Icons.check_box,
                text: currentStudentName.isNotEmpty ? '$currentStudentName · 今日到校' : '今日到校', //[cite: 13]
                bgColor: const Color(0xFFD8F3E5),
                textColor: const Color(0xFF00875A),
                iconColor: const Color(0xFF00A36C),
              ),
              SizedBox(width: 8.w),
              _buildStatusBadge(
                icon: Icons.assignment_outlined,
                text: '作業未繳 1', //[cite: 13]
                bgColor: const Color(0xFFFFF3D6),
                textColor: const Color(0xFF9E6B00),
                iconColor: const Color(0xFFE5A100),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // 學生切換膠囊列表[cite: 13]
          if (_isLoadingStudents)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))), //[cite: 13]
            )
          else if (_students.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_students.length, (index) {
                  final student = _students[index];
                  final isSelected = _selectedStudentIndex == index;
                  final colorTheme = _pillColors[index % _pillColors.length]; //[cite: 13]

                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStudentIndex = index; //[cite: 13]
                        });
                      },
                      child: _buildStudentPill(
                        student.csNm, //[cite: 13]
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

          // 最新公告[cite: 13]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('最新公告', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))), //[cite: 13]
              GestureDetector(
                onTap: () {
                  // 👉 點擊「全部」時，觸發動畫平滑切換到通知頁 (index = 0)
                  final CurvedNavigationBarState? navBarState = _bottomNavigationKey.currentState;
                  if (navBarState != null) {
                    navBarState.setPage(0);
                  }
                },
                behavior: HitTestBehavior.opaque, //[cite: 13]
                child: Row(
                  children: [
                    Text('全部', style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B46C1), fontWeight: FontWeight.bold)), //[cite: 13]
                    Icon(Icons.arrow_forward, size: 14.sp, color: const Color(0xFF6B46C1)), //[cite: 13]
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // ListView.builder 動態渲染最新的 3 筆公告[cite: 13]
          SizedBox(
            height: 140.w, //[cite: 13]
            child: _latestNotices.isEmpty
                ? Center(
              child: Text(
                '目前無最新公告', //[cite: 13]
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
              ),
            )
                : ListView.builder(
              scrollDirection: Axis.horizontal, //[cite: 13]
              itemCount: _latestNotices.length, //[cite: 13]
              itemBuilder: (context, index) {
                final notice = _latestNotices[index]; //[cite: 13]
                // 將第一筆或有置頂標記(pinTop=='Y')的卡片呈現為漸層強調[cite: 13]
                final isGradient = index == 0 || notice.pinTop == 'Y';

                return Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: _buildNoticeCard(
                    isGradient: isGradient,
                    badge: notice.pinTop == 'Y' ? '重要' : null, //[cite: 13]
                    title: notice.title, //[cite: 13]
                    date: _formatDateString(notice.startDate), //[cite: 13]
                    icon: _getNoticeIcon(notice.noticeType), //[cite: 13]
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 22.h),

          // 今日課程[cite: 13]
          Text('今日課程', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))), //[cite: 13]
          SizedBox(height: 12.h),
          _buildCourseCard(time: '16:00', title: '數學', timeBgColor: const Color(0xFFF0F3FA), timeColor: const Color(0xFF7B8DB0)), //[cite: 13]
          SizedBox(height: 10.h),
          _buildCourseCard(
            time: '17:00', //[cite: 13]
            title: '作文',
            timeBgColor: const Color(0xFFE3F7EE),
            timeColor: const Color(0xFF00A36C),
            isHighlight: true, //[cite: 13]
            statusBadge: '上課中', //[cite: 13]
          ),
          SizedBox(height: 10.h),
          _buildCourseCard(time: '18:00', title: '英文', timeBgColor: const Color(0xFFFFF4DF), timeColor: const Color(0xFFF5A623)), //[cite: 13]
          SizedBox(height: 10.h),
          _buildCourseCard(time: '18:30', title: '課輔', timeBgColor: const Color(0xFFFFECEE), timeColor: const Color(0xFFFF5A60)), //[cite: 13]
          SizedBox(height: 22.h),

          // 快速功能[cite: 13]
          Text('快速功能', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E))), //[cite: 13]
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildQuickAction('聯絡簿', Icons.menu_book, const Color(0xFFEDF5FF), const Color(0xFF3282B8)), //[cite: 13]
              _buildQuickAction('Go home', Icons.location_on_outlined, const Color(0xFFFFEFEF), const Color(0xFFE55353)), //[cite: 13]
              _buildQuickAction('課表', Icons.assignment_outlined, const Color(0xFFF3EFFF), const Color(0xFF8C52FF)), //[cite: 13]
              _buildQuickAction('繳費', Icons.account_balance_wallet_outlined, const Color(0xFFFFF7E6), const Color(0xFFE69A00)), //[cite: 13]
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
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(16.r)), //[cite: 13]
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: iconColor), //[cite: 13]
          SizedBox(width: 4.w),
          Text(text, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: textColor)), //[cite: 13]
        ],
      ),
    );
  }

  Widget _buildStudentPill(String name, {required bool isSelected, required Color bgColor, required Color textColor}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20.r)), //[cite: 13]
      child: Text(name, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: textColor)), //[cite: 13]
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
      width: 148.w, //[cite: 13]
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: isGradient
            ? const LinearGradient(
          colors: [Color(0xFF6B7BFD), Color(0xFF3F63F6)], //[cite: 13]
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null, //[cite: 13]
        color: isGradient ? null : const Color(0xFFCCE4FF), //[cite: 13]
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 20.sp)), //[cite: 13]
              if (badge != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h), //[cite: 13]
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF5252), //[cite: 13]
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 10.sp, //[cite: 13]
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
                maxLines: 2, //[cite: 13]
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp, //[cite: 13]
                  fontWeight: FontWeight.bold,
                  height: 1.25, //[cite: 13]
                  color: isGradient ? Colors.white : const Color(0xFF1E1E1E), //[cite: 13]
                ),
              ),
              SizedBox(height: 4.h), //[cite: 13]
              Text(
                date,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isGradient ? Colors.white70 : const Color(0xFF757575), //[cite: 13]
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
        border: isHighlight ? Border.all(color: const Color(0xFF00B074), width: 1.5) : null, //[cite: 13]
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)), //[cite: 13]
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(color: timeBgColor, borderRadius: BorderRadius.circular(14.r)),
            child: Text(time, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: timeColor)), //[cite: 13]
          ),
          SizedBox(width: 14.w),
          Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))), //[cite: 13]
          const Spacer(),
          if (statusBadge != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(color: const Color(0xFF00A86B), borderRadius: BorderRadius.circular(12.r)), //[cite: 13]
              child: Row(
                children: [
                  Icon(Icons.play_arrow, size: 12.sp, color: Colors.white), //[cite: 13]
                  SizedBox(width: 2.w), //[cite: 13]
                  Text(statusBadge, style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold)), //[cite: 13]
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
          width: 70.w, //[cite: 13]
          height: 60.h,
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(14.r)),
          child: Icon(icon, color: iconColor, size: 24.sp), //[cite: 13]
        ),
        SizedBox(height: 6.h), //[cite: 13]
        Text(title, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF424242), fontWeight: FontWeight.w500)), //[cite: 13]
      ],
    );
  }
}