import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class ParentNotificationPage extends StatefulWidget {
  const ParentNotificationPage({super.key});

  @override
  State<ParentNotificationPage> createState() => _ParentNotificationPageState();
}

class _ParentNotificationPageState extends State<ParentNotificationPage> {
  int _tabIndex = 0; // 0: 公告, 1: 問卷

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
                    Text(
                      '通知中心',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                    SizedBox(height: 14.h),

                    // 頂部 Tabs
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 0),
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: _tabIndex == 0 ? const Color(0xFF6366F1) : const Color(0xFFDCDAFE),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '公告',
                                style: TextStyle(
                                  color: _tabIndex == 0 ? Colors.white : const Color(0xFF6366F1),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _tabIndex = 1),
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: _tabIndex == 1 ? const Color(0xFF00B074) : const Color(0xFFD6F5E8),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '問卷',
                                style: TextStyle(
                                  color: _tabIndex == 1 ? Colors.white : const Color(0xFF00B074),
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 18.h),

                    _tabIndex == 0 ? _buildNoticeTab() : _buildSurveyTab(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📣', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '重要',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: const Color(0xFFFF4D4F),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    '暑期課程報名開始',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                '2026/06/18',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
              SizedBox(height: 8.h),
              Text(
                '親愛的家長您好，暑期課程即將開始報名，名額有限，請盡早完成報名。課程涵蓋數學、英文、國語',
                style: TextStyle(fontSize: 12.sp, color: Colors.white, height: 1.4),
              ),
              SizedBox(height: 12.h),
              Text(
                '閱讀全文',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        const Divider(color: Color(0xFFE0E0E0), thickness: 0.8),
        SizedBox(height: 16.h),

        _buildNoticeItemCard(
          title: '6月份月考時間公告',
          date: '2026/06/20',
          content: '本月份月考訂於6月25日（二）至6月27日（四）舉行，請同學們做好充足準備。考試範圍詳見各科老',
        ),
        SizedBox(height: 14.h),

        _buildNoticeItemCard(
          title: '端午節假期通知',
          date: '2026/06/10',
          content: '端午節連假（6月8日至10日）期間本補習班休班，11日（二）起照常上課，請家長與同學留意。如有',
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildNoticeItemCard({
    required String title,
    required String date,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
          ),
          SizedBox(height: 4.h),
          Text(
            date,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(fontSize: 12.sp, color: const Color(0xFF616161), height: 1.4),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Text(
                '閱讀全文',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: const Color(0xFF3872F6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF3872F6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: const Color(0xFF2E9A74),
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E9A74).withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('📢', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4D4F),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '重要',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B694),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      '待填答',
                      style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                '暑期輔導是否參加',
                style: TextStyle(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4.h),
              Text(
                '發布 2026/06/18 · 截止 2026/06/28',
                style: TextStyle(fontSize: 11.sp, color: Colors.white70),
              ),
              SizedBox(height: 8.h),
              Text(
                '本學期暑期輔導將於 7/7 開課，涵蓋數學、英文、國文與自然科。請家長協助確認孩子是否參加，以利分班安排。',
                style: TextStyle(fontSize: 12.sp, color: Colors.white, height: 1.4),
              ),
              SizedBox(height: 14.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 70.w,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3.r),
                          child: LinearProgressIndicator(
                            value: 118 / 186,
                            minHeight: 5.h,
                            backgroundColor: Colors.white30,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '已回覆 118/186',
                        style: TextStyle(fontSize: 10.sp, color: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '前往填寫',
                        style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      Icon(Icons.chevron_right, size: 16.sp, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        const Divider(color: Color(0xFFE0E0E0), thickness: 0.8),
        SizedBox(height: 16.h),

        _buildSurveyItemCard(
          percent: 77,
          progressColor: const Color(0xFF00B074),
          statusBadge: '進行中',
          statusBgColor: const Color(0xFFD6F5E8),
          statusTextColor: const Color(0xFF00BA88),
          targetText: '七、八年級',
          title: '下學期社團意願調查',
          desc: '共開設 12 個社團，請協助孩子填寫前三志願，作',
          deadline: '截止 2026/06/25',
        ),
        SizedBox(height: 14.h),

        _buildSurveyItemCard(
          percent: 94,
          progressColor: const Color(0xFF00B074),
          statusBadge: '已結束',
          statusBgColor: const Color(0xFFE8EEF5),
          statusTextColor: const Color(0xFF7B8DB0),
          targetText: '全校家長',
          title: '午餐供應商滿意度',
          desc: '感謝填答！本次回收率 94%，結果已彙整給家長',
          deadline: '截止 2026/06/09',
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildSurveyItemCard({
    required int percent,
    required Color progressColor,
    required String statusBadge,
    required Color statusBgColor,
    required Color statusTextColor,
    required String targetText,
    required String title,
    required String desc,
    required String deadline,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
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
          SizedBox(
            width: 48.w,
            height: 48.w,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percent / 100,
                  strokeWidth: 4.5.w,
                  backgroundColor: const Color(0xFFEAEFF5),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        statusBadge,
                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold, color: statusTextColor),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      targetText,
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  title,
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
                ),
                SizedBox(height: 2.h),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.sp, color: const Color(0xFF757575)),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12.sp, color: const Color(0xFF9E9E9E)),
                    SizedBox(width: 4.w),
                    Text(
                      deadline,
                      style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 18.sp, color: const Color(0xFFBDBDBD)),
        ],
      ),
    );
  }
}