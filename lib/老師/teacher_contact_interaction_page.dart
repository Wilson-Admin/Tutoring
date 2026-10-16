import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/ChatListResponse.dart';

class TeacherContactInteractionPage extends StatefulWidget {
  final ValueChanged<int>? onUnreadChanged; // 👈 支援回呼通知未讀總數變更[cite: 28]

  const TeacherContactInteractionPage({super.key, this.onUnreadChanged});

  @override
  State<TeacherContactInteractionPage> createState() =>
      _TeacherContactInteractionPageState();
}

class _TeacherContactInteractionPageState
    extends State<TeacherContactInteractionPage> {
  int _selectedCampusIndex = 0; // 0: 全部[cite: 28]
  bool _isLoading = false;

  List<SchoolInfo> _schools = [];
  List<ChatItem> _allChats = [];

  final List<Color> _campusColors = [
    const Color(0xFF5E60CE), // 紫色系[cite: 28]
    const Color(0xFF00B074), // 綠色系[cite: 28]
    const Color(0xFFF59E0B), // 橘黃色系[cite: 28]
    const Color(0xFF3B82F6), // 藍色系[cite: 28]
  ];

  @override
  void initState() {
    super.initState();
    _fetchChatList();
  }

  Future<void> _fetchChatList() async {
    setState(() => _isLoading = true);

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
        // 👈 回呼通知首頁更新導航列未讀 Badge[cite: 28]
        widget.onUnreadChanged?.call(res.data!.unreadTotal);
      }
    } catch (e) {
      debugPrint('[Chat] 讀取聊天室清單失敗: $e');
    } finally {
      if (mounted) {
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
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
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
                    // 頂部標題（已移除返回鍵）
                    Text(
                      '聯絡互動',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 動態分校過濾標籤列[cite: 28]
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

                    // 聊天室內容區塊[cite: 28]
                    if (_isLoading)
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
          );
        },
      ),
    );
  }

  /// 依據學校分組動態產生聊天室清單[cite: 28]
  List<Widget> _buildCampusSections() {
    final List<Widget> sections = [];

    for (int i = 0; i < _schools.length; i++) {
      final school = _schools[i];
      final schoolIndexInTabs = i + 1;

      // 若非全部且非選中分校，則不顯示[cite: 28]
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
        );
      }

      sections.add(SizedBox(height: 16.h));
    }

    return sections;
  }

  /// 分校膠囊標題[cite: 28]
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

  /// 對話列表卡片[cite: 28]
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