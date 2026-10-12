import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../共用函式/app_dialog.dart';

class TeacherPhrasesPage extends StatefulWidget {
  const TeacherPhrasesPage({super.key});

  @override
  State<TeacherPhrasesPage> createState() => _TeacherPhrasesPageState();
}

class _TeacherPhrasesPageState extends State<TeacherPhrasesPage> {
  // 頁籤分類
  final List<String> _tabs = [
    '全部',
    '出席/請假',
    '作業/學習',
    '行為/品德',
    '健康/衛生',
    '活動/通知',
    '鼓勵/讚美',
  ];
  int _currentTabIndex = 0;

  final TextEditingController _inputController = TextEditingController();

  // ─── 系統固定預設（當頁籤為「全部」時永遠以此為準） ───
  static const Map<String, List<String>> _defaultPhrases = {
    '出席/請假': [
      '今日準時到班，出席狀況良好。',
      '今日稍晚到班，已提醒孩子注意上課時間。',
      '請假手續已收到並確認。',
    ],
    '作業/學習': [
      '國文講義作業完成，請家長確認簽名。',
      '請複習今天教的英文單字。',
      '數學習作已批改，請訂正錯題。',
      '上課專心聽講，學習成效良好！',
    ],
    '行為/品德': [
      '主動協助整理班級環境，表現負責。',
      '能友愛同學、樂於分享。',
      '課堂中偶有分心，請協助提醒維持專注力。',
    ],
    '健康/衛生': [
      '今日體溫正常，精神狀況良好。',
      '天氣轉涼，請提醒寶貝多加件薄外套。',
      '今天在校有輕微咳嗽，請多留意水分補充。',
    ],
    '活動/通知': [
      '明天校外教學，請協助寶貝們不要忘記帶水壺。',
      '下週將進行段考複習測驗。',
      '聯絡簿通知單請家長詳閱並簽名後帶回。',
    ],
    '鼓勵/讚美': [
      '今天表現非常積極，值得大大稱讚！',
      '有顯著的進步，繼續保持！',
      '上課勇於發言提問，學習態度很棒！',
    ],
  };

  // 各個別頁籤自訂與持久化的片語資料
  Map<String, List<String>> _customPhrasesMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomPhrases();
  }

  /// 從本地端 SharedPreferences 載入各分類自訂片語
  Future<void> _loadCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('saved_custom_phrases_map_v2');

    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonString);
        final Map<String, List<String>> loaded = {};
        decoded.forEach((key, value) {
          if (value is List) {
            loaded[key] = List<String>.from(value);
          }
        });
        setState(() {
          _customPhrasesMap = loaded;
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('解析本地片語失敗: $e');
      }
    }

    // 若無本地紀錄，複製一份系統預設值供各頁籤操作
    setState(() {
      _customPhrasesMap = Map.from(
        _defaultPhrases.map((k, v) => MapEntry(k, List<String>.from(v))),
      );
      _isLoading = false;
    });
  }

  /// 儲存個別分類片語至本地端
  Future<void> _saveCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_customPhrasesMap);
    await prefs.setString('saved_custom_phrases_map_v2', jsonString);
  }

  /// 新增片語（僅在個別分類頁籤生效）
  void _addPhrase() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    final currentCategory = _tabs[_currentTabIndex];
    if (currentCategory == '全部') return;

    setState(() {
      _customPhrasesMap.putIfAbsent(currentCategory, () => []);
      _customPhrasesMap[currentCategory]!.add(text);
      _inputController.clear();
    });

    _saveCustomPhrases();
  }

  /// 彈跳確認視窗並刪除片語
  Future<void> _confirmDeletePhrase(String category, String phrase) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 48.w),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F5), // 米白底色
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xFFE8E2D9), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
                  child: Text(
                    '確定刪除？',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E2B48),
                    ),
                  ),
                ),
                Container(
                  height: 1.0,
                  color: const Color(0xFFE8E2D9),
                ),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      // 取消按鈕
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(18.r),
                          ),
                          onTap: () => Navigator.pop(ctx, false),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: Text(
                              '取消',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E2B48),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 1.0,
                        color: const Color(0xFFE8E2D9),
                      ),
                      // 確定按鈕（深藍底色、白字）
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(18.r),
                          ),
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2B48),
                              borderRadius: BorderRadius.only(
                                bottomRight: Radius.circular(18.r),
                              ),
                            ),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: Text(
                              '確定',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() {
        _customPhrasesMap[category]?.remove(phrase);
      });
      _saveCustomPhrases();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTabName = _tabs[_currentTabIndex];
    final bool isAllTab = currentTabName == '全部';

    // 取得當前清單
    List<String> displayPhrases = [];
    if (isAllTab) {
      // 「全部」：只呈現純粹的系統預設集合
      for (final list in _defaultPhrases.values) {
        displayPhrases.addAll(list);
      }
    } else {
      // 個別頁籤：呈現本地端儲存與修改後的片語
      displayPhrases = _customPhrasesMap[currentTabName] ?? [];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          '聯絡簿/作業 常用片語',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E1E1E),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon:  Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E1E1E), size: 20.w),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 膠囊分類頁籤列 ───
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _currentTabIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentTabIndex = index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF5C59FD)
                                  : const Color(0xFFF1F0FE),
                              borderRadius: BorderRadius.circular(22.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF6461FE),
                                fontWeight: FontWeight.bold,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 16.h),

                // ─── 「常用句」與橫線分隔線 ───
                Row(
                  children: [
                    Text(
                      '常用句',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF5C59FD),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Expanded(
                      child: Divider(
                        color: Color(0xFF8C86FF),
                        thickness: 1.2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // ─── 新增片語輸入列 ───
                if (!isAllTab) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          constraints: BoxConstraints(
                            minHeight: 46.h,
                            maxHeight: 120.h,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: const Color(0xFF8C86FF), width: 1.5),
                          ),
                          child: TextField(
                            controller: _inputController,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                              hintText: '自訂[$currentTabName]句子後按插入…',
                              hintStyle:  TextStyle(
                                color: Color(0xFFBDBDBD),
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      GestureDetector(
                        onTap: _addPhrase,
                        child: Container(
                          height: 46.h,
                          padding: EdgeInsets.symmetric(horizontal: 18.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5C59FD),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '插入',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                ],

                // ─── 片語列表區塊 ───
                Expanded(
                  child: displayPhrases.isEmpty
                      ? Center(
                    child: Text(
                      '此分類尚無常用片語',
                      style: TextStyle(
                        color: const Color(0xFF9E9E9E),
                        fontSize: 14.sp,
                      ),
                    ),
                  )
                      : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: displayPhrases.length,
                    itemBuilder: (context, idx) {
                      final phrase = displayPhrases[idx];

                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 13.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAEAFF),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFF9A96FF), width: 1.0),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                phrase,
                                style: TextStyle(
                                  color: const Color(0xFF2E2E2E),
                                  fontSize: 13.5.sp,
                                  height: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            // 點擊觸發確認彈窗
                            if (!isAllTab)
                              GestureDetector(
                                onTap: () => _confirmDeletePhrase(currentTabName, phrase),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8.w, top: 2.h),
                                  child: Icon(
                                    Icons.delete_outline,
                                    size: 20.sp,
                                    color: const Color(0xFF757575),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}