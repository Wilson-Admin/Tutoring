import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/NoticeResponse.dart';
import '../資料結構/Structures.dart';
import '../資料結構/SurveyResponse.dart';
import 'SurveyDetailPage.dart';
import 'notice_detail_page.dart';

class ParentNotificationPage extends StatefulWidget {
  final Function(int unreadCount)? onNoticeCountChanged;

  const ParentNotificationPage({super.key, this.onNoticeCountChanged});

  @override
  State<ParentNotificationPage> createState() => _ParentNotificationPageState();
}

class _ParentNotificationPageState extends State<ParentNotificationPage> {
  int _tabIndex = 0; // 0: 公告, 1: 問卷
  bool _isLoading = true;
  List<NoticeItem> _notices = [];

  // 取得 API Base URL
  final String baseUrl = AuthService.baseUrl;

  List<SurveyItem> _surveys = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // 只有在非下拉刷新（例如剛進頁面 _isLoading 為 true）時才顯示全版載入框，避免下拉時畫面閃爍
    if (_notices.isEmpty && _surveys.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '0900000016';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      // 同時或分別抓取公告與問卷
      final noticeRes = await AuthService.getActiveNotices(
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      final surveyRes = await AuthService.getActiveSurveys(
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (noticeRes.success && noticeRes.data != null) {
            _notices = noticeRes.data!.items;
          }
          if (surveyRes.success && surveyRes.data != null) {
            _surveys = surveyRes.data!.items;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 處理圖片的完整網址轉換邏輯
  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    if (path.startsWith('~/')) return '$baseUrl/${path.substring(2)}';
    if (path.startsWith('/')) return '$baseUrl$path';
    return '$baseUrl/$path';
  }

  /// 根據 NoticeType 取得標籤文字
  String _getNoticeTagText(NoticeItem notice) {
    switch (notice.noticeType) {
      case 'S':
        return '校園公告';
      case 'A':
        return '活動公告';
      case 'M':
        return '系統維護公告';
      default:
        return '公告';
    }
  }

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

  /// 處理時間格式
  String _formatDateString(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      // 加上 RefreshIndicator 實現下拉刷新
      child: RefreshIndicator(
        onRefresh: _fetchData,
        color: const Color(0xFF6366F1),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              // 必須設定AlwaysScrollableScrollPhysics，才能在內容不足一頁時也能下拉刷新
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
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

                      _isLoading
                          ? Padding(
                        padding: EdgeInsets.symmetric(vertical: 50.h),
                        child: const Center(child: CircularProgressIndicator()),
                      )
                          : (_tabIndex == 0 ? _buildNoticeTab() : _buildSurveyTab()),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoticeTab() {
    if (_notices.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 50.h),
        child: Center(
          child: Text(
            '目前沒有任何公告',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
          ),
        ),
      );
    }

    final NoticeItem? topNotice = _notices.cast<NoticeItem?>().firstWhere(
          (element) => element?.pinTop == 'Y',
      orElse: () => null,
    );

    final listNotices = topNotice != null
        ? _notices.where((e) => e.noticeNo != topNotice.noticeNo).toList()
        : _notices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (topNotice != null) ...[
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 傳入整包 NoticeItem 給第二層
                  builder: (context) => NoticeDetailPage(notice: topNotice),
                ),
              );
            },
            child: Container(
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
                      Text(_getNoticeIcon(topNotice.noticeType), style: TextStyle(fontSize: 18.sp)),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        margin: EdgeInsets.only(right: 8.w),
                        child: Text(
                          '重要',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFFFF4D4F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          topNotice.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  // 第一層只顯示時間標籤
                  Text(
                    topNotice.startDate.replaceAll('-', '/'),
                    style: TextStyle(fontSize: 11.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 12.h),
                  // 補回閱讀全文
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
          ),
          SizedBox(height: 16.h),
          const Divider(color: Color(0xFFE0E0E0), thickness: 0.8),
          SizedBox(height: 16.h),
        ],

        // 動態生成下方其餘的公告列表
        ...listNotices.map((notice) {
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _buildNoticeItemCard(notice),
          );
        }),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// 依據新 UI 重新建構卡片，僅顯示標籤、時間與 Title、閱讀全文
  Widget _buildNoticeItemCard(NoticeItem notice) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // 傳入整包 NoticeItem 給第二層
            builder: (context) => NoticeDetailPage(notice: notice),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: notice.pinTop == 'Y' ? const Color(0xFFF4EBFF) : Colors.white,
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
            // 第一行：標籤與時間
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    _getNoticeTagText(notice),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  _formatDateString(notice.startDate),
                  style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // 第二行：標題
            Text(
              notice.title,
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10.h),

            // 第三行：補回閱讀全文
            Row(
              children: [
                Text(
                  '閱讀全文',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF3872F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.chevron_right, size: 16.sp, color: const Color(0xFF3872F6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyTab() {
    if (_surveys.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 50.h),
        child: Center(
          child: Text(
            '目前沒有任何問卷',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
          ),
        ),
      );
    }

    // 依照規則：家長先看到還沒填的問卷（優先取第一筆未填寫的作為置頂綠底框），再看到已完成的歷史問卷
    final SurveyItem? topUnanswered = _surveys.cast<SurveyItem?>().firstWhere(
          (element) => element?.answered == false,
      orElse: () => null,
    );

    // 剩下的問卷列表（排除置頂的那一筆未填問卷）
    final listSurveys = topUnanswered != null
        ? _surveys.where((e) => e.surveyNo != topUnanswered.surveyNo || e.csNo != topUnanswered.csNo).toList()
        : _surveys;

    // 格式化結束日期的小幫手函式
    String formatEndDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '長期有效';
      return dateStr.replaceAll('-', '/');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. 若有尚未作答的問卷，最上方以綠底重要卡片呈現
        if (topUnanswered != null) ...[
          GestureDetector(
            onTap: () async{
              // TODO: 導向填寫問卷頁面
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SurveyDetailPage(
                    surveyNo: topUnanswered.surveyNo,
                    csNo: topUnanswered.csNo,
                    answered: topUnanswered.answered,
                  ),
                ),
              );
              if (result == true) {
                _fetchData(); // 填寫完成返回後重新整理列表
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F), // 質感綠底
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A9D8F).withOpacity(0.3),
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
                      Text('📋', style: TextStyle(fontSize: 18.sp)),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        margin: EdgeInsets.only(right: 6.w),
                        child: Text(
                          '重要',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFFFF4D4F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        margin: EdgeInsets.only(right: 8.w),
                        child: Text(
                          '待填答',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '對象：${topUnanswered.csNm}',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    topUnanswered.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '發布 ${topUnanswered.startDate.replaceAll('-', '/')} • 截止 ${formatEndDate(topUnanswered.endDate)}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    topUnanswered.detail,
                    style: TextStyle(fontSize: 13.sp, color: Colors.white.withOpacity(0.9)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '前往填寫',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(Icons.chevron_right, size: 18.sp, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(color: Color(0xFFE0E0E0), thickness: 0.8),
          SizedBox(height: 16.h),
        ],

        // 2. 下方其餘的問卷列表
        ...listSurveys.map((survey) {
          return Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _buildSurveyItemCard(survey),
          );
        }),
        SizedBox(height: 20.h),
      ],
    );
  }

  /// 已作答或一般清單的白底卡片
  Widget _buildSurveyItemCard(SurveyItem survey) {
    final bool isAnswered = survey.answered;
    final endDateStr = (survey.endDate == null || survey.endDate!.isEmpty)
        ? '長期有效'
        : survey.endDate!.replaceAll('-', '/');

    return GestureDetector(
      onTap: () async{
        // TODO: 點擊查看問卷詳情或填寫結果
        // 點擊列表中的任一問卷，導向詳情頁面（會自動依據 answered 狀態呼叫對應 API）
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SurveyDetailPage(
              surveyNo: survey.surveyNo,
              csNo: survey.csNo,
              answered: survey.answered,
            ),
          ),
        );
        if (result == true) {
          _fetchData(); // 填寫完成返回後重新整理列表
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左側狀態標籤或圖示
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isAnswered ? const Color(0xFFE2F0D9) : const Color(0xFFFFF2CC),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          isAnswered ? '已完成' : '待填答',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isAnswered ? const Color(0xFF385723) : const Color(0xFFB45F06),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '對象：${survey.csNm}',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    survey.title,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13.sp, color: const Color(0xFF9E9E9E)),
                      SizedBox(width: 4.w),
                      Text(
                        '截止 $endDateStr',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                      ),
                      if (isAnswered && survey.responseAt != null) ...[
                        SizedBox(width: 12.w),
                        Text(
                          '已回覆',
                          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF2A9D8F)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 20.sp, color: const Color(0xFFBDBDBD)),
          ],
        ),
      ),
    );
  }
}