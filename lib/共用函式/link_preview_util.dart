import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String url;

  LinkPreviewData({this.title, this.description, this.imageUrl, required this.url});
}

class LinkPreviewUtil {
  // 快取已解析過的網址，避免重複請求
  static final Map<String, LinkPreviewData> _cache = {};

  static Future<LinkPreviewData?> fetch(String url) async {
    if (_cache.containsKey(url)) return _cache[url];

    try {
      // 設置 timeout 避免壞網址卡住
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final document = parser.parse(response.body);
      String? title, description, imageUrl;

      // 遍歷所有 meta 標籤尋找 Open Graph 或 Twitter Card 資料
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

      // Fallback: 如果沒有 og:title，抓取網頁原生的 <title>
      if (title == null) {
        final titleTags = document.getElementsByTagName('title');
        if (titleTags.isNotEmpty) title = titleTags.first.text;
      }

      // 只要有標題或圖片就判定為有效預覽
      if (title != null || imageUrl != null) {
        final data = LinkPreviewData(title: title, description: description, imageUrl: imageUrl, url: url);
        _cache[url] = data;
        return data;
      }
    } catch (e) {
      debugPrint('[LinkPreviewUtil] 抓取失敗: $e');
    }
    return null;
  }
}