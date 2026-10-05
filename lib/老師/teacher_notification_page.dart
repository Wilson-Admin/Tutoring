import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TeacherNotificationPage extends StatefulWidget {
  const TeacherNotificationPage({super.key});

  @override
  State<TeacherNotificationPage> createState() => _TeacherNotificationPageState();
}

class _TeacherNotificationPageState extends State<TeacherNotificationPage> {
  int _tabIndex = 0; // 0: 公告, 1: 問卷
  int _targetIndex = 1; // 0: 全校, 1: 班級, 2: 個別學生

  final List<String> _classes = ['美茵班', '安親班', '一年級', '二年級', '三年級', '四年級', '五年級', '六年級'];
  final Set<String> _selectedClasses = {'美茵班'};

  final TextEditingController _contentController = TextEditingController();

  final List<Map<String, String>> _templates = [
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
                            onTap: () => setState(() => _tabIndex = 1),
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
                color: Colors.black.withOpacity(0.02),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
                '校外教學意願調查',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
              ),
              SizedBox(height: 4.h),
              Text('全校 · 42 個班級', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF9E9E9E))),
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
                      '2026-08-14 09:20',
                      style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF424242)),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),

              Row(
                children: [
                  _buildSurveyMetricBox('1,284', '發送成功', const Color(0xFFE4F9EF), const Color(0xFF00BA88)),
                  SizedBox(width: 8.w),
                  _buildSurveyMetricBox('37', '發送失敗', const Color(0xFFFFEAEA), const Color(0xFFFF4D4F)),
                  SizedBox(width: 8.w),
                  _buildSurveyMetricBox('968', '家長回覆', const Color(0xFFEAF3FF), const Color(0xFF1890FF)),
                ],
              ),
              SizedBox(height: 16.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('回覆率', style: TextStyle(fontSize: 11.sp, color: const Color(0xFF616161))),
                  Text(
                    '75% (968/1284)',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1890FF)),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value: 0.75,
                  minHeight: 6.h,
                  backgroundColor: const Color(0xFFEEF2F6),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3872F6)),
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                '共送達 1321 位，失敗 37 位（帳號未綁定或已停用）',
                style: TextStyle(fontSize: 10.sp, color: const Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),

        _buildSectionTitle('每題答覆狀況'),
        SizedBox(height: 12.h),

        _buildQuestionStatCard(
          qNum: 'Q1.',
          question: '是否同意孩子參加本次校外教學？',
          options: [
            {'label': '同意', 'count': '812', 'percent': '84%', 'value': 0.84},
            {'label': '不同意', 'count': '96', 'percent': '10%', 'value': 0.10},
            {'label': '需再討論', 'count': '60', 'percent': '6%', 'value': 0.06},
          ],
        ),
        SizedBox(height: 12.h),

        _buildQuestionStatCard(
          qNum: 'Q2.',
          question: '希望的交通方式',
          options: [
            {'label': '遊覽車', 'count': '690', 'percent': '71%', 'value': 0.71},
            {'label': '大眾運輸', 'count': '188', 'percent': '19%', 'value': 0.19},
            {'label': '家長接送', 'count': '90', 'percent': '9%', 'value': 0.09},
          ],
        ),
        SizedBox(height: 20.h),
      ],
    );
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

  Widget _buildQuestionStatCard({
    required String qNum,
    required String question,
    required List<Map<String, dynamic>> options,
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
                '$qNum ',
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF7B8DB0)),
              ),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: const Color(0xFF212121)),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...options.map((opt) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(opt['label'] as String, style: TextStyle(fontSize: 11.sp, color: const Color(0xFF616161))),
                      Text(
                        '${opt['count']}  (${opt['percent']})',
                        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: const Color(0xFF424242)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: LinearProgressIndicator(
                      value: (opt['value'] as num).toDouble(),
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