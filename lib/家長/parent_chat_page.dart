import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/ChatListResponse.dart';

class ParentChatPage extends StatefulWidget {
  final ValueChanged<int>? onUnreadChanged; // 👈 增加未讀數量變更回呼

  const ParentChatPage({super.key, this.onUnreadChanged});

  @override
  State<ParentChatPage> createState() => _ParentChatPageState();
}

class _ParentChatPageState extends State<ParentChatPage> {
  bool _isLoading = false;
  List<ChatItem> _chats = [];

  // 頭像背景色調色盤
  final List<Color> _avatarColors = [
    const Color(0xFFF59E0B), // 暖橘
    const Color(0xFF7C69FF), // 靛紫
    const Color(0xFF00B7D4), // 湖水藍
    const Color(0xFF00B074), // 翠綠
    const Color(0xFFEC4899), // 粉紅
  ];

  @override
  void initState() {
    super.initState();
    _fetchParentChats();
  }

  Future<void> _fetchParentChats() async {
    setState(() => _isLoading = true);

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

      if (!mounted) return;

      if (res.success && res.data != null) {
        setState(() {
          _chats = res.data!.chats;
        });
        // 👈 回呼通知首頁更新導航列未讀 Badge
        widget.onUnreadChanged?.call(res.data!.unreadTotal);
      }
    } catch (e) {
      debugPrint('[ParentChat] 讀取家長聊天室失敗: $e');
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
                    // 頁面標題
                    Text(
                      '聯絡互動',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 20.h),

                    // 聊天室卡片列表
                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF7C69FF)),
                        ),
                      )
                    else if (_chats.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Center(
                          child: Text(
                            '目前無任何對話訊息',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF9E9E9E),
                            ),
                          ),
                        ),
                      )
                    else
                      ...List.generate(_chats.length, (index) {
                        final chat = _chats[index];
                        final avatarColor = _avatarColors[index % _avatarColors.length];
                        final initialLetter = chat.studentNm.isNotEmpty
                            ? chat.studentNm.substring(0, 1)
                            : '學';

                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _buildChatCard(
                            letter: initialLetter,
                            avatarBgColor: avatarColor,
                            title: '${chat.studentNm} 群組',
                            tag: chat.classNm.isNotEmpty ? chat.classNm : null,
                            message: chat.lastMessage.isNotEmpty ? chat.lastMessage : '尚無對話記錄',
                            time: _formatTime(chat.lastMessageAt),
                            badgeCount: chat.unreadCount,
                            isHighlight: chat.unreadCount > 0,
                            isMessageBold: chat.unreadCount > 0,
                          ),
                        );
                      }),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatCard({
    required String letter,
    required Color avatarBgColor,
    required String title,
    required String message,
    required String time,
    String? tag,
    int badgeCount = 0,
    bool isHighlight = false,
    bool isMessageBold = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: isHighlight
            ? Border.all(color: const Color(0xFFB5EDF7), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
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
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: avatarBgColor,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.all(3.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4D4F),
                      shape: BoxShape.circle,
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16.w,
                      minHeight: 16.w,
                    ),
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
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    if (tag != null) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F8FC),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00B7D4),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: isMessageBold ? FontWeight.bold : FontWeight.w400,
                    color: isMessageBold ? const Color(0xFF2C3E50) : const Color(0xFF8B95A5),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            time,
            style: TextStyle(
              fontSize: 11.sp,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}