import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../API/auth_service.dart';
import '../資料結構/NoticeResponse.dart';
import '../共用函式/image_download_util.dart'; // 👈 引入共用下載方法

class NoticeDetailPage extends StatelessWidget {
  final NoticeItem notice;

  final String baseUrl = AuthService.baseUrl;

  const NoticeDetailPage({super.key, required this.notice});

  /// 處理圖片與檔案的完整網址轉換邏輯，並進行 URL 編碼
  String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    String fullUrl = path;

    if (path.startsWith('~/')) {
      fullUrl = '$baseUrl/${path.substring(2)}';
    } else if (path.startsWith('/')) {
      fullUrl = '$baseUrl$path';
    } else if (!path.startsWith('http://') && !path.startsWith('https://')) {
      fullUrl = '$baseUrl/$path';
    }

    // 將中文檔名或空白轉換為合法網址 (例如: 螢幕擷取畫面 2026-10-30 113306.png)
    return Uri.encodeFull(fullUrl);
  }

  /// 核心發送網址的方法：區分外部下載(PDF/檔案)與內部網頁(一般URL)
  Future<void> _launchURL(BuildContext context, String urlString, {bool isExternal = false}) async {
    final fullUrlString = _getFullUrl(urlString);
    final Uri url = Uri.parse(fullUrlString);

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: isExternal ? LaunchMode.externalApplication : LaunchMode.inAppWebView,
        );
      } else {
        // 避開 Android 權限判定失準問題，強制嘗試啟動
        await launchUrl(
          url,
          mode: isExternal ? LaunchMode.externalApplication : LaunchMode.inAppWebView,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('無法開啟該連結，請檢查網路或網址是否有效')),
        );
      }
    }
  }

  /// 針對「內文純文字」的網址，自動判別 URL 類型並執行對應行為
  void _handleTextUrlClick(BuildContext context, String urlString) {
    final fullUrlString = _getFullUrl(urlString);
    final lowerUrl = fullUrlString.toLowerCase();

    if (lowerUrl.endsWith('.png') ||
        lowerUrl.endsWith('.jpg') ||
        lowerUrl.endsWith('.jpeg') ||
        lowerUrl.endsWith('.gif') ||
        lowerUrl.endsWith('.webp')) {
      _showImageDialog(context, fullUrlString);
    } else if (lowerUrl.endsWith('.pdf')) {
      _launchURL(context, fullUrlString, isExternal: true); // PDF 外部下載
    } else {
      _launchURL(context, fullUrlString, isExternal: false); // 一般網頁內部打開
    }
  }

  /// 原生解析「內文純文字」網址並轉換為可點擊的 TextSpan
  List<InlineSpan> _buildTextSpans(BuildContext context, String text, TextStyle baseStyle) {
    final List<InlineSpan> spans = [];
    final RegExp urlRegex = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    final matches = urlRegex.allMatches(text);
    int lastMatchEnd = 0;

    for (var match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start), style: baseStyle));
      }
      final String url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: baseStyle.copyWith(
            color: const Color(0xFF3872F6),
            decoration: TextDecoration.underline,
          ),
          // 內文網址呼叫自動判斷邏輯
          recognizer: TapGestureRecognizer()..onTap = () => _handleTextUrlClick(context, url),
        ),
      );
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: baseStyle));
    }
    return spans;
  }

  /// 點擊圖片滿版放大查看，右下角提供下載按鈕
  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(dialogContext).pop(),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                bottom: 30.h,
                right: 20.w,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFF6366F1),
                  // 👈 改為使用共用下載方法 image_download_util
                  onPressed: () {
                    ImageDownloadUtil.saveImageToGallery(context, imageUrl);
                  },
                  child: const Icon(Icons.download, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateString(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 嚴格依照 API 的 fileType 來過濾與分類附件
    final imageFiles = notice.files.where((f) => f.fileType == 'P').toList();
    final documentFiles = notice.files.where((f) => f.fileType == 'D' || f.fileType == 'L').toList();

    final TextStyle contentStyle = TextStyle(
      fontSize: 16.sp,
      color: const Color(0xFF333333),
      height: 1.8,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 自訂返回按鈕
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: EdgeInsets.only(bottom: 16.h, right: 16.w, top: 8.h),
                  child: Icon(Icons.arrow_back_ios, color: const Color(0xFF1E1E1E), size: 24.sp),
                ),
              ),

              // 標題區
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📣', style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      notice.title,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF333333),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                _formatDateString(notice.startDate),
                style: TextStyle(fontSize: 16.sp, color: const Color(0xFF666666)),
              ),
              SizedBox(height: 24.h),

              // 內文 (文字內的網址採用正則解析)
              RichText(
                text: TextSpan(
                  children: _buildTextSpans(context, notice.detail, contentStyle),
                ),
              ),
              SizedBox(height: 30.h),

              // P (圖片) 區塊
              if (imageFiles.isNotEmpty) ...[
                ...imageFiles.map((img) {
                  final fullImageUrl = _getFullUrl(img.fileLink);
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: GestureDetector(
                      onTap: () => _showImageDialog(context, fullImageUrl),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: Image.network(
                          fullImageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200.h,
                              color: const Color(0xFFF5F5F5),
                              child: const Center(child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 200.h,
                            color: const Color(0xFFF5F5F5),
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 20.h),
              ],

              // D (PDF) 與 L (外部連結) 區塊
              if (documentFiles.isNotEmpty) ...[
                Text(
                  '相關連結與附件',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: const Color(0xFF333333)),
                ),
                SizedBox(height: 12.h),
                ...documentFiles.map((doc) {
                  final isLink = doc.fileType == 'L'; // 若為 'L' 則是外部連結，'D' 則是 PDF
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: InkWell(
                      onTap: () {
                        // 👈 完全依靠 fileType 判斷行為
                        if (doc.fileType == 'D') {
                          // PDF 交給外部瀏覽器觸發下載/預覽
                          _launchURL(context, doc.fileLink, isExternal: true);
                        } else if (doc.fileType == 'L') {
                          // 外部連結直接在 App 內部打開
                          _launchURL(context, doc.fileLink, isExternal: false);
                        }
                      },
                      borderRadius: BorderRadius.circular(8.r),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLink ? Icons.link : Icons.picture_as_pdf,
                              color: isLink ? const Color(0xFF3872F6) : const Color(0xFFFF4D4F),
                              size: 24.sp,
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                doc.fileName,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: const Color(0xFF333333),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Icon(
                                isLink ? Icons.chevron_right : Icons.download,
                                color: const Color(0xFF9E9E9E),
                                size: 24.sp
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}