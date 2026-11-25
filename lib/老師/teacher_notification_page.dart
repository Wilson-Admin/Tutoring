import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutoring/API/auth_service.dart';

import '../資料結構/AdminSurveyListResponse.dart';
import '../資料結構/AdminSurveyStatisticsResponse.dart';

typedef NoticeTemplate = Map<String, String>;

class TeacherNotificationPage extends StatefulWidget {
  /// 若外部有指定單一問卷編號，則直接呼叫該筆問卷統計 API
  final String? surveyNo;

  const TeacherNotificationPage({super.key, this.surveyNo});

  @override
  State<TeacherNotificationPage> createState() => _TeacherNotificationPageState();
}

class _TeacherNotificationPageState extends State<TeacherNotificationPage> {
  int _tabIndex = 0; // 0: 公告, 1: 問卷
  int _targetIndex = 1; // 0: 全校, 1: 班級, 2: 個別學生

  // 問卷列表與統計狀態
  bool _isLoadingSurveys = false;
  String? _surveyError;
  List<AdminSurveyItem> _surveys = [];
  bool _hasLoadedSurveys = false;

  // 各問卷的「每題答覆狀況」展開狀態與統計資料
  final Set<String> _expandedSurveys = {};
  final Set<String> _loadingStats = {};
  final Map<String, AdminSurveyStatisticsData> _statisticsMap = {};
  final Map<String, String> _statsErrorMap = {};

  final List<String> _classes = ['美茵班', '安親班', '一年級', '二年級', '三年級', '四年級', '五年級', '六年級'];
  final Set<String> _selectedClasses = {'美茵班'};

  final TextEditingController _contentController = TextEditingController();

  final List<NoticeTemplate> _templates = [
    {
      'title': '考試提醒',
      'content': '各位家長您好，接下來本週【_日期_】將舉行【_科目_】考試，請督促孩子準備複習。',
    },
    {
      'title': '作業通知',
      'content': '各位家長您好，孩子今天的【_科目_】作業為【_內容_】，請協助確認孩子有完成作業。',
    },
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 載入問卷列表並取得各筆問卷統計
  Future<void> _fetchSurveys() async {
    setState(() {
      _isLoadingSurveys = true;
      _surveyError = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'M';


      // 取得所有問卷列表後，並行載入每筆問卷統計 API
      final res = await AuthService.getSurveys(
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (!mounted) return;

      if (res.success && res.data != null) {
        final items = res.data!.items;
        setState(() {
          _hasLoadedSurveys = true;
          _surveys = items;
          _statisticsMap.clear();
          _statsErrorMap.clear();
        });

        await Future.wait(
          items.map((item) => _fetchSurveyStatistics(item.surveyNo)),
        );
      } else {
        setState(() {
          _hasLoadedSurveys = true;
          _surveyError = res.msg.isNotEmpty ? res.msg : '取得問卷列表失敗';
        });
      }
    } catch (e) {
      debugPrint('[Survey] 讀取問卷資料失敗: $e');
      if (!mounted) return;
      setState(() {
        _surveyError = '讀取問卷資料發生異常，請稍後再試';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingSurveys = false);
      }
    }
  }

  /// 呼叫單筆問卷統計 API (GET /api/tutoring/surveys/{surveyNo}/statistics)
  Future<void> _fetchSurveyStatistics(String surveyNo) async {
    if (_loadingStats.contains(surveyNo)) return;

    setState(() {
      _loadingStats.add(surveyNo);
      _statsErrorMap.remove(surveyNo);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'M';

      final res = await AuthService.getSurveyStatistics(
        surveyNo: surveyNo,
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (!mounted) return;

      setState(() {
        if (res.success && res.data != null) {
          _statisticsMap[surveyNo] = res.data!;
        } else {
          _statsErrorMap[surveyNo] = res.msg.isNotEmpty ? res.msg : '取得問卷統計失敗';
        }
      });
    } catch (e) {
      debugPrint('[SurveyStats] 讀取問卷統計失敗 ($surveyNo): $e');
      if (!mounted) return;
      setState(() {
        _statsErrorMap[surveyNo] = '讀取問卷統計發生異常';
      });
    } finally {
      if (mounted) {
        setState(() => _loadingStats.remove(surveyNo));
      }
    }
  }

  /// 切換展開 / 收納「每題答覆狀況」
  void _toggleSurveyExpand(String surveyNo) {
    setState(() {
      if (_expandedSurveys.contains(surveyNo)) {
        _expandedSurveys.remove(surveyNo);
      } else {
        _expandedSurveys.add(surveyNo);
      }
    });

    if (!_statisticsMap.containsKey(surveyNo) && !_loadingStats.contains(surveyNo)) {
      _fetchSurveyStatistics(surveyNo);
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
                                color: _tabIndex == 0 ? const Color(0xFF6C63FF) : const Color(0xFFDCDAFE),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '公告',
                                style: TextStyle(
                                  color: _tabIndex == 0 ? Colors.white : const Color(0xFF6C63FF),
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
                            onTap: () {
                              setState(() => _tabIndex = 1);
                              if (!_hasLoadedSurveys) {
                                _fetchSurveys();
                              }
                            },
                            child: Container(
                              height: 44.h,
                              decoration: BoxDecoration(
                                color: _tabIndex == 1 ? const Color(0xFF00BA88) : const Color(0xFFD6F5E8),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '問卷',
                                style: TextStyle(
                                  color: _tabIndex == 1 ? Colors.white : const Color(0xFF00BA88),
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

                    // 依分頁切換內容
                    _tabIndex == 0 ? _buildNoticeView() : _buildSurveyView(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoticeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('傳送對象'),
        SizedBox(height: 10.h),
        Row(
          children: [
            _buildTargetCard(icon: Icons.storefront_outlined, title: '全校', subtitle: '所有班級', index: 0),
            SizedBox(width: 10.w),
            _buildTargetCard(icon: Icons.crop_square_outlined, title: '班級', subtitle: '選擇班級', index: 1),
            SizedBox(width: 10.w),
            _buildTargetCard(icon: Icons.person_outline, title: '個別學生', subtitle: '選擇學生', index: 2),
          ],
        ),
        SizedBox(height: 20.h),

        _buildSectionTitle('選擇班級（可複選）'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _classes.map((cls) {
            final isSelected = _selectedClasses.contains(cls);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected ? _selectedClasses.remove(cls) : _selectedClasses.add(cls);
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: isSelected ? null : Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Text(
                  cls,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isSelected ? Colors.white : const Color(0xFF616161),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20.h),

        _buildSectionTitle('公告內容'),
        SizedBox(height: 10.h),
        Container(
          height: 130.h,
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFDCDFE6), width: 1.0),
          ),
          child: TextField(
            controller: _contentController,
            maxLines: null,
            style: TextStyle(fontSize: 14.sp),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: '輸入公告內容，或套用下方範本…',
              hintStyle: TextStyle(color: const Color(0xFFBDBDBD), fontSize: 13.sp),
            ),
          ),
        ),
        SizedBox(height: 20.h),

        _buildSectionTitle('公告範本'),
        SizedBox(height: 10.h),
        ..._templates.map((tpl) => _buildTemplateCard(tpl['title']!, tpl['content']!)),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildTargetCard({required IconData icon, required String title, required String subtitle, required int index}) {
    final isSelected = _targetIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _targetIndex = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: isSelected ? Border.all(color: const Color(0xFF8C86FF), width: 1.5) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFFF2F3F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isSelected ? Colors.white : const Color(0xFF757575), size: 20.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? const Color(0xFF6C63FF) : const Color(0xFF212121),
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String content) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _contentController.text = content;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE6E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6.w,
                  height: 6.w,
                  decoration: const BoxDecoration(color: Color(0xFF6C63FF), shape: BoxShape.circle),
                ),
                SizedBox(width: 6.w),
                Text(
                  title,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF212121)),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              content,
              style: TextStyle(fontSize: 11.sp, color: const Color(0xFF757575), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyView() {
    if (_isLoadingSurveys && _surveys.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 60.h),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BA88)),
        ),
      );
    }

    if (_surveyError != null && _surveys.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: Column(
            children: [
              Text(
                _surveyError!,
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFFFF4D4F)),
              ),
              SizedBox(height: 12.h),
              ElevatedButton(
                onPressed: _fetchSurveys,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00BA88),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: const Text('重新載入'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 問卷上方標題與重新整理按鈕
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('問卷列表（共 ${_surveys.length} 份）'),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isLoadingSurveys ? null : _fetchSurveys,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F9EF),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingSurveys)
                      SizedBox(
                        width: 14.sp,
                        height: 14.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF00BA88),
                        ),
                      )
                    else
                      Icon(Icons.refresh, size: 15.sp, color: const Color(0xFF00BA88)),
                    SizedBox(width: 4.w),
                    Text(
                      _isLoadingSurveys ? '更新中...' : '重新整理',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF00BA88),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        if (_surveys.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 60.h),
            child: Center(
              child: Text(
                '目前尚無問卷資料',
                style: TextStyle(fontSize: 14.sp, color: const Color(0xFF9E9E9E)),
              ),
            ),
          )
        else
          ..._surveys.map((survey) => _buildSurveyItemBlock(survey)),

        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildSurveyItemBlock(AdminSurveyItem survey) {
    final bool isExpanded = _expandedSurveys.contains(survey.surveyNo);
    final bool isLoadingStat = _loadingStats.contains(survey.surveyNo);
    final AdminSurveyStatisticsData? stat = _statisticsMap[survey.surveyNo];
    final String? statError = _statsErrorMap[survey.surveyNo];

    // 改抓問卷統計 API 的 data.summary 欄位
    final summary = stat?.summary;
    final int targetCount = summary?.targetCount ?? 0;
    final int successCount = summary?.successCount ?? 0; // 發送成功 / 共送達
    final int failCount = summary?.failCount ?? 0; // 發送失敗 / 失敗位
    final int responseCount = summary?.responseCount ?? 0; // 家長回覆
    final double responseRate = (summary?.responseRate ?? 0.0).toDouble(); // 回覆率

    // 進度條數值（0.0 ~ 1.0）
    final double rate = targetCount > 0
        ? (responseCount / targetCount).clamp(0.0, 1.0)
        : (responseRate / 100.0).clamp(0.0, 1.0);

    // 整數去掉 .0（如 100.0 -> 100%），非整數保留一位小數
    final String percentText = responseRate % 1 == 0
        ? '${responseRate.toInt()}%'
        : '${responseRate.toStringAsFixed(1)}%';

    final String typeText = '';
    /*
    survey.surveyType == 'A'
        ? '全校'
        : (survey.surveyType == 'C' ? '班級' : survey.surveyType);
    */

    final String subtitleText = survey.detail.isNotEmpty
        ? '$typeText · ${survey.detail}'
        : typeText;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 標題與副標題
          Text(
            stat?.title.isNotEmpty == true ? stat!.title : survey.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E1E1E),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            subtitleText,
            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
          ),

          // 發送時間
          if (survey.addDate.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F5FA),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14.sp, color: const Color(0xFF757575)),
                      SizedBox(width: 4.w),
                      Text('發送時間', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF757575))),
                    ],
                  ),
                  Text(
                    survey.addDate,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 14.h),

          // 發送成功 / 發送失敗 / 家長回覆
          Row(
            children: [
              _buildSurveyMetricBox('$successCount', '發送成功', const Color(0xFFE4F9EF), const Color(0xFF00BA88)),
              SizedBox(width: 8.w),
              _buildSurveyMetricBox('$failCount', '發送失敗', const Color(0xFFFFEAEA), const Color(0xFFFF4D4F)),
              SizedBox(width: 8.w),
              _buildSurveyMetricBox('$responseCount', '家長回覆', const Color(0xFFEAF3FF), const Color(0xFF1890FF)),
            ],
          ),
          SizedBox(height: 16.h),

          // 回覆率
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('回覆率', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF616161))),
              Text(
                '$percentText ($responseCount/$targetCount)',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1890FF),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 6.h,
              backgroundColor: const Color(0xFFEEF2F6),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3872F6)),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '共送達 $successCount 位，失敗 $failCount 位（帳號未綁定或已停用）',
            style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
          ),

          // 2. 卡片底部：每題答覆狀況（點擊展開 / 收合）
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFF0F2F6)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _toggleSurveyExpand(survey.surveyNo),
            child: Padding(
              padding: EdgeInsets.only(top: 12.h, bottom: isExpanded ? 10.h : 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '每題答覆狀況',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        isExpanded ? '收合' : '展開',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF00BA88),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18.sp,
                        color: const Color(0xFF00BA88),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 展開內容區（位於該筆 item 卡片下方）
          if (isExpanded) ...[
            if (isLoadingStat)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00BA88)),
                ),
              )
            else if (statError != null)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Center(
                  child: Column(
                    children: [
                      Text(statError, style: TextStyle(fontSize: 12.sp, color: const Color(0xFFFF4D4F))),
                      TextButton(
                        onPressed: () => _fetchSurveyStatistics(survey.surveyNo),
                        child: const Text('重新載入'),
                      ),
                    ],
                  ),
                ),
              )
            else if (stat == null || stat.questions.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    '尚無題目答覆資料',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
                  ),
                )
              else
                ...stat.questions.asMap().entries.map((entry) {
                  final isLast = entry.key == stat.questions.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 10.h),
                    child: _buildQuestionStatCard(entry.value),
                  );
                }),

            // 家長回覆狀況
            SizedBox(height: 16.h),
            _buildRespondentsSection(stat!.respondents),
          ],
        ],
      ),
    );
  }

  Widget _buildRespondentsSection(List<SurveyRespondent> respondents) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '家長回覆狀況',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        SizedBox(height: 10.h),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFE6EBF2), width: 1.0),
          ),
          child: respondents.isEmpty
              ? Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h),
            child: Center(
              child: Text(
                '目前尚無家長回覆',
                style: TextStyle(fontSize: 12.sp, color: const Color(0xFF9E9E9E)),
              ),
            ),
          )
              : Column(
            children: respondents.asMap().entries.map((entry) {
              final index = entry.key;
              final respondent = entry.value;
              final isLast = index == respondents.length - 1;
              return Column(
                children: [
                  _buildRespondentRow(respondent),
                  if (!isLast)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F6)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRespondentRow(SurveyRespondent r) {
    final String studentNm = r.studentNm.trim();
    final String parentNm = r.parentNm.trim();
    final String classNm = r.classNm.trim();

    // 頭像取學生姓氏（無學生姓名時退回取家長稱謂首字）
    final String avatarText = studentNm.isNotEmpty
        ? studentNm.characters.first
        : (parentNm.isNotEmpty ? parentNm.characters.first : '家');

    // 主標題：學生姓名 家長；副標題：班級 · 家長稱謂
    final String titleText = studentNm.isNotEmpty ? '$studentNm 家長' : parentNm;
    final String subtitleText = [classNm, parentNm].where((e) => e.isNotEmpty).join(' · ');

    final bool hasResponded = r.responseAt.trim().isNotEmpty;
    final String statusText = hasResponded ? '已回覆' : '未回覆';
    final Color badgeBgColor = hasResponded ? const Color(0xFFDCF7EC) : const Color(0xFFFEF3D9);
    final Color badgeTextColor = hasResponded ? const Color(0xFF00B074) : const Color(0xFFD99A2B);
    final String timeText = _formatResponseTime(r.responseAt);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          // 左側圓形姓氏頭像
          Container(
            width: 38.w,
            height: 38.w,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF1F7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // 中間姓名與班級/家長稱謂
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                if (subtitleText.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  Text(
                    subtitleText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF8C98A9),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // 右側回覆狀態膠囊與回覆時間
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                timeText,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: const Color(0xFF8C98A9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 將 "2026-07-02 10:15:32" 格式化為 "07-02 10:15"，空值顯示 "–"
  String _formatResponseTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '–';
    final dt = DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
    if (dt != null) {
      final mm = dt.month.toString().padLeft(2, '0');
      final dd = dt.day.toString().padLeft(2, '0');
      final hh = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$mm-$dd $hh:$min';
    }
    return trimmed;
  }

  Widget _buildSurveyMetricBox(String value, String label, Color bgColor, Color textColor) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12.r)),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor)),
            SizedBox(height: 2.h),
            Text(label, style: TextStyle(fontSize: 10.sp, color: textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionStatCard(SurveyStatQuestion q) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q${q.questionSr}. ',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF7B8DB0)),
              ),
              Expanded(
                child: Text(
                  q.question,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF212121)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...q.options.map((opt) {
            final double optRate = opt.rate;
            // 進度條數值（0.0 ~ 1.0），比照 summary.responseRate 為 0~100 制
            final double progressValue = (optRate / 100.0).clamp(0.0, 1.0);
            // 整數去掉 .0（如 50.0 -> 50%），非整數保留一位小數
            final String rateText = optRate % 1 == 0
                ? '${optRate.toInt()}%'
                : '${optRate.toStringAsFixed(1)}%';

            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          opt.optionText,
                          style: TextStyle(fontSize: 11.sp, color: const Color(0xFF616161)),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${opt.count}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF212121),
                            ),
                          ),
                          Text(
                            '($rateText)',
                            style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 5.h,
                      backgroundColor: const Color(0xFFF0F2F6),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B074)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1E1E1E),
      ),
    );
  }
}