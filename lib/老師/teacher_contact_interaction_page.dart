import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TeacherContactInteractionPage extends StatefulWidget {
  const TeacherContactInteractionPage({super.key});

  @override
  State<TeacherContactInteractionPage> createState() =>
      _TeacherContactInteractionPageState();
}

class _TeacherContactInteractionPageState
    extends State<TeacherContactInteractionPage> {
  int _selectedCampusIndex = 0; // 0: 全部, 1: 輔威校, 2: 華森校, 3: 五王校
  final List<String> _campuses = ['全部', '輔威校', '華森校', '五王校'];

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
                    // 頂部返回箭頭與標題
                    Row(
                      children: [
                        Container(
                          width: 34.w,
                          height: 34.w,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10.r),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 14.sp, color: const Color(0xFF616161)),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          '聯絡互動',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E1E1E),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // 分校過濾標籤列
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_campuses.length, (index) {
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
                                _campuses[index],
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

                    // 1. 輔威校 區塊
                    if (_selectedCampusIndex == 0 || _selectedCampusIndex == 1) ...[
                      _buildCampusHeader('輔威校', const Color(0xFF5E60CE)),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFF5E60CE),
                        name: '學生A',
                        members: '4位成員',
                        message: '王小明媽媽：請問下週有考試嗎？',
                        time: '09:41',
                        badgeCount: 3,
                        isHighlightBorder: true,
                        borderColor: const Color(0xFFDCDAFE),
                      ),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFF5E60CE),
                        name: '學生B',
                        members: '3 位成員',
                        message: '我：課程通知已更新，請查看',
                        time: '昨天',
                        isMutedText: true,
                      ),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFF5E60CE),
                        name: '學生C',
                        members: '3 位成員',
                        message: '鄭家豪媽媽：老師辛苦了！',
                        time: '10:02',
                        badgeCount: 1,
                        isHighlightBorder: true,
                        borderColor: const Color(0xFFDCDAFE),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // 2. 華森校 區塊
                    if (_selectedCampusIndex == 0 || _selectedCampusIndex == 2) ...[
                      _buildCampusHeader('華森校', const Color(0xFF00B074)),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFF00B074),
                        name: '學生1',
                        members: '5 位成員',
                        message: '我：作業請週五前上傳平台',
                        time: '週二',
                        isMutedText: true,
                      ),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFF00B074),
                        name: '學生2',
                        members: '6 位成員',
                        message: '蘇志遠爸爸：謝謝老師！',
                        time: '11:15',
                        badgeCount: 2,
                        isHighlightBorder: true,
                        borderColor: const Color(0xFFC7F3E2),
                      ),
                      SizedBox(height: 20.h),
                    ],

                    // 3. 五王校 區塊
                    if (_selectedCampusIndex == 0 || _selectedCampusIndex == 3) ...[
                      _buildCampusHeader('五王校', const Color(0xFFF59E0B)),
                      SizedBox(height: 10.h),
                      _buildChatCard(
                        avatarColor: const Color(0xFFF59E0B),
                        name: '學生ㄅ',
                        members: '7 位成員',
                        message: '我：期中口說考試時間公告',
                        time: '週三',
                        isMutedText: true,
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// 分校膠囊標題
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

  /// 對話列表卡片
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
                      style: TextStyle(fontSize: 9.sp, color: Colors.white, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
                ),
                SizedBox(height: 2.h),
                Text(
                  members,
                  style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
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