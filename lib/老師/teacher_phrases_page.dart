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

  final PageController _pageController = PageController();
  final ScrollController _tabScrollController = ScrollController();
  late Map<String, TextEditingController> _inputControllers;

  // ─── 系統固定預設（預設值全歸類在「全部」） ───
  static const Map<String, List<String>> _defaultPhrases = {
    '全部': [
      '今日準時到班，出席狀況良好。',
      '今日稍晚到班，已提醒孩子注意上課時間。',
      '今日上課遲到，請家長協助提醒準時到班。',
      '今日孩子請假，課程內容可於返班後再行補充。',
      '今日因身體不適請假，請孩子在家多休息。',
      '今日因家庭因素請假，已協助記錄缺課內容。',
      '今日提早離班，相關課程內容將再協助補充。',
      '近期到班時間穩定，請繼續保持。',
      '近期有數次遲到情形，請家長協助留意到班時間。',
      '本日出席正常，課程皆有完整參與。',
      '請假手續已收到並確認。',
      '今日作業已完成，整體完成度良好。',
      '今日作業大致完成，少部分內容需要再訂正。',
      '今日作業尚未完成，請回家後協助督促完成。',
      '今日作業有缺交情形，請孩子明日補交。',
      '國文講義作業完成，請家長確認簽名。',
      '請複習今天教的英文單字。',
      '數學習作已批改，請訂正錯題。',
      '上課專心聽講，學習成效良好！',
      '主動協助整理班級環境，表現負責。',
      '能友愛同學、樂於分享。',
      '課堂中偶有分心，請協助提醒維持專注力。',
      '今日體溫正常，精神狀況良好。',
      '天氣轉涼，請提醒寶貝多加件薄外套。',
      '今天在校有輕微咳嗽，請多留意水分補充。',
      '明天校外教學，請協助寶貝們不要忘記帶水壺。',
      '下週將進行段考複習測驗。',
      '聯絡簿通知單請家長詳閱並簽名後帶回。',
      '今天表現非常積極，值得大大稱讚！',
      '有顯著的進步，繼續保持！',
      '上課勇於發言提問，學習態度很棒！',
    ]
  };

  // 👈 新增：使用單一扁平化列表作為全域唯一資料源，完美支援跨分類的全域拖曳排序
  List<Map<String, String>> _globalPhrases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _inputControllers = {
      for (var tab in _tabs) if (tab != '全部') tab: TextEditingController()
    };
    _loadCustomPhrases();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    for (var controller in _inputControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 產生唯一 ID 給 ReorderableListView 使用
  String _generateId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// 載入片語，並提供從舊版 Map 結構無痛升級的機制
  Future<void> _loadCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStringV4 = prefs.getString('saved_custom_phrases_flat_v4');

    if (jsonStringV4 != null && jsonStringV4.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStringV4);
        setState(() {
          _globalPhrases = decoded.map((e) => Map<String, String>.from(e)).toList();
          _isLoading = false;
        });
        return;
      } catch (e) {
        debugPrint('解析本地片語失敗 v4: $e');
      }
    }

    // 若無 v4，嘗試讀取 v3 (舊版) 進行無痛轉換
    final jsonStringV3 = prefs.getString('saved_custom_phrases_map_v3');
    if (jsonStringV3 != null && jsonStringV3.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStringV3);
        int idCounter = 0;
        _globalPhrases.clear();
        decoded.forEach((key, value) {
          if (value is List) {
            for (var phrase in value) {
              _globalPhrases.add({
                'id': 'mig_${idCounter++}',
                'category': key,
                'phrase': phrase.toString(),
              });
            }
          }
        });
        _saveCustomPhrases();
        setState(() => _isLoading = false);
        return;
      } catch (e) {
        debugPrint('解析本地片語失敗 v3: $e');
      }
    }

    // 若無任何紀錄，載入預設值
    _resetToDefault(showConfirm: false);
  }

  Future<void> _saveCustomPhrases() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_custom_phrases_flat_v4', jsonEncode(_globalPhrases));
  }

  /// 新增片語（自動給予分類屬性）
  void _addPhrase(String category) {
    if (category == '全部') return;

    final text = _inputControllers[category]?.text.trim() ?? '';
    if (text.isEmpty) return;

    setState(() {
      _globalPhrases.insert(0, {
        'id': _generateId(),
        'category': category,
        'phrase': text,
      });
      _inputControllers[category]?.clear();
    });

    _saveCustomPhrases();
  }

  /// 👈 核心邏輯：支援在「全部」與「子分類」中精準重排
  void _onReorder(String tabName, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }

      if (tabName == '全部') {
        // 在「全部」頁籤，直接調整全域順序
        final item = _globalPhrases.removeAt(oldIndex);
        _globalPhrases.insert(newIndex, item);
      } else {
        // 在子分類，只針對該分類的項目進行重排，但不影響其他分類的穿插順序
        List<int> globalIndices = [];
        List<Map<String, String>> filteredItems = [];

        for (int i = 0; i < _globalPhrases.length; i++) {
          if (_globalPhrases[i]['category'] == tabName) {
            globalIndices.add(i);
            filteredItems.add(_globalPhrases[i]);
          }
        }

        final item = filteredItems.removeAt(oldIndex);
        filteredItems.insert(newIndex, item);

        // 將重排後的子項目放回原本對應的相對全域位置中
        for (int i = 0; i < globalIndices.length; i++) {
          _globalPhrases[globalIndices[i]] = filteredItems[i];
        }
      }
    });
    _saveCustomPhrases();
  }

  Future<void> _resetToDefault({bool showConfirm = true}) async {
    if (showConfirm) {
      final confirm = await AppDialog.showConfirm(
        context: context,
        title: '恢復初始值',
        message: '這將會清除您自行新增的所有片語，並恢復原廠設定，確定要執行嗎？',
        confirmText: '確定',
        cancelText: '取消',
      );
      if (!confirm) return;
    }

    setState(() {
      _globalPhrases.clear();
      int idCounter = 0;
      for (var phrase in _defaultPhrases['全部']!) {
        _globalPhrases.add({
          'id': 'def_${idCounter++}',
          'category': '全部',
          'phrase': phrase,
        });
      }

      for (var controller in _inputControllers.values) {
        controller.clear();
      }
      _isLoading = false;
    });

    if (showConfirm) {
      _saveCustomPhrases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已恢復初始值')),
        );
      }
    }
  }

  Future<void> _confirmDeletePhrase(String id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 48.w),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F5),
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
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(18.r)),
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
                      Container(width: 1.0, color: const Color(0xFFE8E2D9)),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.only(bottomRight: Radius.circular(18.r)),
                          onTap: () => Navigator.pop(ctx, true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E2B48),
                              borderRadius: BorderRadius.only(bottomRight: Radius.circular(18.r)),
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
        _globalPhrases.removeWhere((e) => e['id'] == id);
      });
      _saveCustomPhrases();
    }
  }

  void _scrollToTab(int index) {
    if (!_tabScrollController.hasClients) return;
    double offset = (index * 85.w) - (MediaQuery.of(context).size.width / 2) + 40.w;
    if (offset < 0) offset = 0;
    final maxScroll = _tabScrollController.position.maxScrollExtent;
    if (offset > maxScroll) offset = maxScroll;

    _tabScrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          icon: Icon(Icons.arrow_back_ios_new, color: const Color(0xFF1E1E1E), size: 20.w),
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
                SingleChildScrollView(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(_tabs.length, (index) {
                      final isSelected = _currentTabIndex == index;
                      return Padding(
                        padding: EdgeInsets.only(right: 8.w),
                        child: GestureDetector(
                          onTap: () {
                            FocusScope.of(context).unfocus();
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF5C59FD) : const Color(0xFFF1F0FE),
                              borderRadius: BorderRadius.circular(22.r),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : const Color(0xFF6461FE),
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
                      child: Divider(color: Color(0xFF8C86FF), thickness: 1.2),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _currentTabIndex = index;
                      });
                      _scrollToTab(index);
                    },
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tabName = _tabs[index];
                      final isAllTab = tabName == '全部';

                      // 過濾要顯示的清單
                      List<Map<String, String>> pagePhrases = [];
                      if (isAllTab) {
                        pagePhrases = List.from(_globalPhrases);
                      } else {
                        pagePhrases = _globalPhrases.where((e) => e['category'] == tabName).toList();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isAllTab) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Container(
                                    constraints: BoxConstraints(minHeight: 46.h, maxHeight: 120.h),
                                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                      border: Border.all(color: const Color(0xFF8C86FF), width: 1.5),
                                    ),
                                    child: TextField(
                                      controller: _inputControllers[tabName],
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      style: TextStyle(fontSize: 13.sp, height: 1.4),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                                        hintText: '自訂[$tabName]句子後按插入…',
                                        hintStyle: TextStyle(color: const Color(0xFFBDBDBD), fontSize: 13.sp),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                GestureDetector(
                                  onTap: () => _addPhrase(tabName),
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
                          Expanded(
                            child: pagePhrases.isEmpty
                                ? Center(
                              child: Text(
                                '此分類尚無常用片語',
                                style: TextStyle(color: const Color(0xFF9E9E9E), fontSize: 14.sp),
                              ),
                            )
                                : ReorderableListView.builder(
                              physics: const BouncingScrollPhysics(),
                              // 👈 修改：移除原廠白底方框陰影，並加上透明 Material 確保拖曳視覺純淨
                              proxyDecorator: (Widget child, int index, Animation<double> animation) {
                                return Material(
                                  type: MaterialType.transparency,
                                  elevation: 0,
                                  color: Colors.transparent,
                                  child: child,
                                );
                              },
                              onReorder: (oldIndex, newIndex) => _onReorder(tabName, oldIndex, newIndex),
                              itemCount: pagePhrases.length,
                              itemBuilder: (context, idx) {
                                final item = pagePhrases[idx];
                                return _buildPhraseItem(item);
                              },
                            ),
                          ),
                          if (isAllTab) ...[
                            SizedBox(height: 10.h),
                            GestureDetector(
                              onTap: _resetToDefault,
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B66FF),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '回復初始值',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
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

  // 獨立抽出的項目 UI 組件
  Widget _buildPhraseItem(Map<String, String> item) {
    final id = item['id']!;
    final phrase = item['phrase']!;

    return Container(
      key: ValueKey(id), // 必須提供唯一 Key 供 ReorderableListView 排序使用
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
          GestureDetector(
            onTap: () => _confirmDeletePhrase(id),
            child: Padding(
              padding: EdgeInsets.only(left: 8.w, top: 2.h),
              child: Icon(
                Icons.delete_outline,
                size: 20.sp,
                color: const Color(0xFF757575),
              ),
            ),
          ),
          // 提示可用於拖曳的圖示
          Padding(
            padding: EdgeInsets.only(left: 12.w, top: 2.h),
            child: Icon(
              Icons.drag_handle_rounded,
              size: 20.sp,
              color: const Color(0xFF9A96FF),
            ),
          ),
        ],
      ),
    );
  }
}