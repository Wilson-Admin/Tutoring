import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/ChatListResponse.dart';
import 'TeacherChatRoomPage.dart';

class TeacherContactInteractionPage extends StatefulWidget {
  final ValueChanged<int>? onUnreadChanged;

  const TeacherContactInteractionPage({super.key, this.onUnreadChanged});

  @override
  State<TeacherContactInteractionPage> createState() =>
      _TeacherContactInteractionPageState();
}

class _TeacherContactInteractionPageState
    extends State<TeacherContactInteractionPage> {
  int _selectedCampusIndex = 0;
  bool _isLoading = false;

  List<SchoolInfo> _schools = [];
  List<ChatItem> _allChats = [];

  Timer? _refreshTimer;

  final List<Color> _campusColors = [
    const Color(0xFF5E60CE),
    const Color(0xFF00B074),
    const Color(0xFFF59E0B),
    const Color(0xFF3B82F6),
  ];

  @override
  void initState() {
    super.initState();
    _fetchChatList();

    // 背景定時輪詢：每 10 秒自動在背景刷新一次聊天列表，確保收到新訊息
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchChatList(isAutoRefresh: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchChatList({bool isAutoRefresh = false}) async {
    // 若是背景自動刷新則不顯示畫面中央的 loading
    if (_allChats.isEmpty && !isAutoRefresh) {
      setState(() => _isLoading = true);
    }

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

      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _schools = res.data!.schools;
          _allChats = res.data!.chats;
        });
        widget.onUnreadChanged?.call(res.data!.unreadTotal);
      }
    } catch (e) {
      debugPrint('[Chat] 讀取聊天室清單失敗: $e');
    } finally {
      if (mounted && !isAutoRefresh) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawTime);
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$hh:$mm';
      }
      return '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      if (rawTime.length >= 16) {
        return rawTime.substring(11, 16);
      }
      return rawTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final campusTabs = ['全部', ..._schools.map((s) => s.depmNm)];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: () => _fetchChatList(isAutoRefresh: false),
            color: const Color(0xFF5E60CE),
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  minWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '聯絡互動',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1E1E1E),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(campusTabs.length, (index) {
                            final isSelected = _selectedCampusIndex == index;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCampusIndex = index),
                              child: Container(
                                margin: EdgeInsets.only(right: 10.w),
                                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF1E272E) : Colors.white,
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: isSelected
                                      ? null
                                      : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  campusTabs[index],
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : const Color(0xFF8B95A5),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      if (_isLoading && _allChats.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: const Center(
                            child: CircularProgressIndicator(color: Color(0xFF5E60CE)),
                          ),
                        )
                      else if (_allChats.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.h),
                          child: Center(
                            child: Text(
                              '目前無任何對話訊息',
                              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
                            ),
                          ),
                        )
                      else
                        ..._buildCampusSections(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildCampusSections() {
    final List<Widget> sections = [];

    for (int i = 0; i < _schools.length; i++) {
      final school = _schools[i];
      final schoolIndexInTabs = i + 1;

      if (_selectedCampusIndex != 0 && _selectedCampusIndex != schoolIndexInTabs) {
        continue;
      }

      final chatsInSchool = _allChats.where((c) => c.depmNo == school.depmNo).toList();
      if (chatsInSchool.isEmpty) continue;

      final themeColor = _campusColors[i % _campusColors.length];

      sections.add(_buildCampusHeader(school.depmNm, themeColor));
      sections.add(SizedBox(height: 10.h));

      for (final chat in chatsInSchool) {
        sections.add(
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: GestureDetector(
              onTap: () async {
                // 1. 跳轉至內部聊天室
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TeacherChatRoomPage(
                      chatId: chat.chatId,
                      chatName: chat.studentNm,
                      subTitle: chat.classNm,
                      themeColor: themeColor,
                    ),
                  ),
                );

                // 2. 退出聊天室後，樂觀更新：立刻將未讀紅點歸零
                if (chat.unreadCount > 0) {
                  setState(() {
                    chat.unreadCount = 0;
                  });
                  int newTotalUnread = _allChats.fold(0, (sum, item) => sum + item.unreadCount);
                  widget.onUnreadChanged?.call(newTotalUnread);
                }

                // 3. 立刻觸發一次背景 API 刷新
                // 這樣能保證自己剛送出的文字/圖片，能馬上更新在外層卡片的「最後一則訊息」與「時間」
                _fetchChatList(isAutoRefresh: true);
              },
              child: _buildChatCard(
                avatarColor: themeColor,
                name: chat.studentNm,
                members: chat.classNm,
                message: chat.lastMessage,
                time: _formatTime(chat.lastMessageAt),
                badgeCount: chat.unreadCount,
                isHighlightBorder: chat.unreadCount > 0,
                borderColor: themeColor.withOpacity(0.3),
                isMutedText: chat.unreadCount == 0,
              ),
            ),
          ),
        );
      }

      sections.add(SizedBox(height: 16.h));
    }

    return sections;
  }

  Widget _buildCampusHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 5.w,
          height: 16.h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard({
    required Color avatarColor,
    required String name,
    required String members,
    required String message,
    required String time,
    int badgeCount = 0,
    bool isHighlightBorder = false,
    Color borderColor = Colors.transparent,
    bool isMutedText = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: isHighlightBorder ? Border.all(color: borderColor, width: 1.2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: avatarColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.people_alt, color: Colors.white, size: 22.sp),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D4F),
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                    child: Text(
                      badgeCount.toString(),
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
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  members,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isMutedText ? FontWeight.normal : FontWeight.bold,
                    color: isMutedText ? const Color(0xFF9E9E9E) : const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            time,
            style: TextStyle(fontSize: 10.sp, color: const Color(0xFFBDBDBD)),
          ),
        ],
      ),
    );
  }
}