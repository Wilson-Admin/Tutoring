import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class ParentChatPage extends StatelessWidget {
  const ParentChatPage({super.key});

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

                    // 群組卡片 1：小朋友A 群組
                    _buildChatCard(
                      letter: 'A',
                      avatarBgColor: const Color(0xFFF59E0B),
                      title: '小朋友A 群組',
                      message: '課程通知已更新請查看',
                      time: '10:15',
                      badgeCount: 2,
                    ),
                    SizedBox(height: 12.h),

                    // 群組卡片 2：小朋友B 群組
                    _buildChatCard(
                      letter: 'B',
                      avatarBgColor: const Color(0xFF7C69FF),
                      title: '小朋友B 群組',
                      message: '老師：怡君進步非常明顯！繼續加油 🌟',
                      time: '週四',
                    ),
                    SizedBox(height: 12.h),

                    // 群組卡片 3：小朋友C 群組
                    _buildChatCard(
                      letter: 'C',
                      avatarBgColor: const Color(0xFF00B7D4),
                      title: '小朋友C 群組',
                      tag: '黃俊豪',
                      message: '我：好的，感謝老師！',
                      time: '09:30',
                      badgeCount: 1,
                      isHighlight: true,
                      isMessageBold: true,
                    ),
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