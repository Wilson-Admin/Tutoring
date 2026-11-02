import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import '../資料結構/SurveyDetailResponse.dart';

class SurveyDetailPage extends StatefulWidget {
  final String surveyNo;
  final String csNo;
  final bool answered;

  const SurveyDetailPage({
    super.key,
    required this.surveyNo,
    required this.csNo,
    required this.answered,
  });

  @override
  State<SurveyDetailPage> createState() => _SurveyDetailPageState();
}

class _SurveyDetailPageState extends State<SurveyDetailPage> {
  bool _isLoading = true;
  SurveyDetailData? _surveyData;

  // 記錄使用者的選擇：key 為 questionSr，value 為選中的 optionSr
  final Map<int, int> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _fetchSurveyDetail();
  }

  Future<void> _fetchSurveyDetail() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '0900000016';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      SurveyDetailResponse res;
      if (widget.answered) {
        res = await AuthService.getSurveyHistory(
          surveyNo: widget.surveyNo,
          csNo: widget.csNo,
          userNo: userNo,
          xApiKey: xApiKey,
          roleCode: roleCode,
        );
      } else {
        res = await AuthService.getSurveyForm(
          surveyNo: widget.surveyNo,
          csNo: widget.csNo,
          userNo: userNo,
          xApiKey: xApiKey,
          roleCode: roleCode,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (res.success && res.data != null) {
            _surveyData = res.data!;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 顯示確定送出確認對話框（對應圖中「確定送出？」）
  void _showSubmitConfirmDialog() {
    if (_surveyData == null) return;

    // 檢查是否全部題目皆已作答（所有題目皆為必答）
    for (var q in _surveyData!.questions) {
      if (!_selectedAnswers.containsKey(q.questionSr)) {
        _showCustomMessageDialog('所有題目皆為必答，請完成全部題目後再送出。');
        return;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        titlePadding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 12.h),
        contentPadding: EdgeInsets.symmetric(horizontal: 24.w),
        actionsPadding: EdgeInsets.zero,
        title: Center(
          child: Text(
            '確定送出？',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
          ),
        ),
        content: Text(
          '送出後將無法修改問卷內容，是否確認送出？',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        ),
        actions: [
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 20.h),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20.r)),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('取消', style: TextStyle(color: Colors.grey[600], fontSize: 15.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
                Container(width: 1, height: 48.h, color: const Color(0xFFEEEEEE)),
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomRight: Radius.circular(20.r)),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _submitAnswers();
                    },
                    child: Text(
                      '確定',
                      style: TextStyle(color: const Color(0xFF1E1E1E), fontSize: 15.sp, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 顯示提示訊息對話框
  void _showCustomMessageDialog(String message, {VoidCallback? onDismiss}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF1E1E1E)),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: 120.w,
              height: 40.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B074),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  if (onDismiss != null) onDismiss();
                },
                child: Text('確定', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAnswers() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userNo = prefs.getString('user_no') ?? '0900000016';
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      // 呼叫送出問卷 API
      final res = await AuthService.submitSurvey(
        surveyNo: widget.surveyNo,
        csNo: widget.csNo,
        answers: _selectedAnswers,
        userNo: userNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res['success'] == true) {
          // 成功後顯示「已收到您回覆的表單！」對話框，點擊確定後返回上一頁
          _showCustomMessageDialog(
            res['msg'] ?? '已收到您回覆的表單！',
            onDismiss: () {
              Navigator.pop(context, true); // 返回上一頁並重新整理列表
            },
          );
        } else {
          _showCustomMessageDialog(res['msg'] ?? '送出失敗');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showCustomMessageDialog('網路連線失敗，請稍後再試。');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          widget.answered ? '問卷歷史紀錄' : '填寫問卷',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00B074)))
          : _surveyData == null
          ? Center(child: Text('無法取得問卷資料', style: TextStyle(fontSize: 14.sp, color: Colors.grey)))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部標題與說明卡片
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: widget.answered ? const Color(0xFFE2F0D9) : const Color(0xFFE8F8F5),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: widget.answered ? const Color(0xFF385723).withOpacity(0.3) : const Color(0xFF00B074).withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: widget.answered ? const Color(0xFF385723) : const Color(0xFF00B074),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                widget.answered ? '已完成' : '待填答',
                                style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            if (_surveyData!.student != null)
                              Text(
                                '學生：${_surveyData!.student!.csNm} (${_surveyData!.student!.classNm})',
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          _surveyData!.title,
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          _surveyData!.detail,
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          widget.answered && _surveyData!.responseAt != null
                              ? '回覆時間：${_surveyData!.responseAt}'
                              : '截止日期：${_surveyData!.endDate ?? "長期有效"}',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // 題目列表
                  widget.answered
                      ? _buildAnsweredHistoryList()
                      : _buildUnansweredFormList(),
                ],
              ),
            ),
          ),

          // 底部送出按鈕 (僅未填寫時顯示)
          if (!widget.answered)
            Container(
              padding: EdgeInsets.all(16.w),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B074),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                    elevation: 0,
                  ),
                  onPressed: _showSubmitConfirmDialog,
                  child: Text(
                    '傳送',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 未填寫時的表單清單（可點選選項）
  Widget _buildUnansweredFormList() {
    return Column(
      children: _surveyData!.questions.map((q) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${q.questionSr}. ',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: const Color(0xFF00B074)),
                  ),
                  Expanded(
                    child: Text(
                      '${q.question} *',
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...q.options.map((opt) {
                final bool isSelected = _selectedAnswers[q.questionSr] == opt.optionSr;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAnswers[q.questionSr] = opt.optionSr;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F8F5) : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00B074) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? const Color(0xFF00B074) : Colors.grey[400],
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            opt.optionText,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isSelected ? const Color(0xFF00B074) : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 已填寫時的歷史紀錄清單（唯讀檢視）
  Widget _buildAnsweredHistoryList() {
    return Column(
      children: _surveyData!.answers.map((ans) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${ans.questionSr}. ',
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                  ),
                  Expanded(
                    child: Text(
                      ans.question,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F0D9).withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: const Color(0xFF385723).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF385723), size: 18),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        ans.optionText,
                        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xFF385723)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}