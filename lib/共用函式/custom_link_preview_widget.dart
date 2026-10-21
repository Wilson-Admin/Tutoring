import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

/// 儲存解析後的網址預覽資料
class LinkPreviewData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  LinkPreviewData({this.title, this.description, this.imageUrl, required this.url});
}

/// 負責發送請求與解析 HTML Meta 標籤的工具，並自帶快取機制
class LinkPreviewUtil {
  // 快取已解析過的網址，避免 ListView 滑動時重複請求
  static final Map<String, LinkPreviewData> _cache = {};

  static Future<LinkPreviewData?> fetch(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    try {
      // 設置 5 秒 timeout，避免壞網址卡住畫面
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      String? title, description, imageUrl;

      // 遍歷所有 meta 標籤尋找 Open Graph (og:) 或 Twitter Card 資料
      final metaTags = document.getElementsByTagName('meta');
      for (final meta in metaTags) {
        final property = meta.attributes['property'] ?? meta.attributes['name'];
        final content = meta.attributes['content'];

        if (content == null || content.isEmpty) continue;

        if (property == 'og:title' || property == 'twitter:title') {
          title ??= content;
        } else if (property == 'og:description' || property == 'twitter:description' || property == 'description') {
          description ??= content;
        } else if (property == 'og:image' || property == 'twitter:image') {
          imageUrl ??= content;
        }
      }

      // Fallback: 如果 meta 標籤沒寫標題，改抓取網頁原生的 <title>
      if (title == null) {
        final titleTags = document.getElementsByTagName('title');
        if (titleTags.isNotEmpty) title = titleTags.first.text;
      }

      // 只要有標題或圖片就判定為有效預覽卡片
      if (title != null || imageUrl != null) {
        final data = LinkPreviewData(title: title, description: description, imageUrl: imageUrl, url: url);
        _cache[url] = data;
        return data;
      }
    } catch (e) {
      debugPrint('[LinkPreviewUtil] 網址預覽抓取失敗: $e');
    }
    return null;
  }
}

/// 獨立的網址預覽卡片 UI 元件
class CustomLinkPreviewWidget extends StatefulWidget {
  final String url;
  final bool isMe; // 用來判斷是否為自己發送的，以適配不同氣泡的背景色與字體顏色

  const CustomLinkPreviewWidget({
    Key? key,
    required this.url,
    required this.isMe
  }) : super(key: key);

  @override
  State<CustomLinkPreviewWidget> createState() => _CustomLinkPreviewWidgetState();
}

class _CustomLinkPreviewWidgetState extends State<CustomLinkPreviewWidget> {
  LinkPreviewData? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await LinkPreviewUtil.fetch(widget.url);
    if (mounted) {
      setState(() {
        _data = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 讀取中：顯示小型轉圈指示器
    if (_isLoading) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: SizedBox(
            height: 16.w,
            width: 16.w,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                color: widget.isMe ? Colors.white54 : Colors.grey
            )
        ),
      );
    }

    // 解析失敗或無資料：直接隱藏，不會影響到純文字訊息的顯示
    if (_data == null) return const SizedBox.shrink();

    // 解析成功：繪製帶有圓角與邊框的預覽卡片
    return Container(
      margin: EdgeInsets.only(top: 8.h),
      constraints: BoxConstraints(maxWidth: 250.w), // 避免圖片過大撐破氣泡
      decoration: BoxDecoration(
        color: widget.isMe ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: widget.isMe ? Colors.white24 : Colors.grey.shade300),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 渲染縮圖 (如果有抓到)
          if (_data!.imageUrl != null && _data!.imageUrl!.startsWith('http'))
            Image.network(
              _data!.imageUrl!,
              height: 120.h,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          // 渲染標題與敘述
          Padding(
            padding: EdgeInsets.all(8.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_data!.title != null)
                  Text(
                    _data!.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis, // 過長顯示刪節號
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: widget.isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                if (_data!.description != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    _data!.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: widget.isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}