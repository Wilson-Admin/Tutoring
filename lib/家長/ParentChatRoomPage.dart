import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../API/auth_service.dart';
import 'package:flutter/services.dart';

import '../共用函式/custom_link_preview_widget.dart';
import '../共用函式/image_download_util.dart';
import 'package:url_launcher/url_launcher.dart';

class ParentChatRoomPage extends StatefulWidget {
  final String chatId;
  final String chatName;
  final String subTitle;
  final Color themeColor;

  const ParentChatRoomPage({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.subTitle,
    required this.themeColor,
  });

  @override
  State<ParentChatRoomPage> createState() => _ParentChatRoomPageState();
}

class _ParentChatRoomPageState extends State<ParentChatRoomPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<dynamic> _messages = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _nextBefore;
  String _currentUserNo = '';

  Map<String, dynamic>? _chatInfo;

  bool _isSending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initUserAndFetchMessages();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50 &&
          !_isLoading &&
          _hasMore) {
        _fetchMessages(loadMore: true);
      }
    });

    // 每 10 秒自動在背景拉取新訊息
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchMessages(isAutoRefresh: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _initUserAndFetchMessages() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserNo = prefs.getString('user_no') ?? '';
    await _fetchMessages();
  }

  Future<void> _fetchMessages({bool loadMore = false, bool isAutoRefresh = false}) async {
    if (_isLoading) return;
    if (!isAutoRefresh) setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      // 家長端強制使用 P
      final roleCode = prefs.getString('role_code') ?? 'P';

      final res = await AuthService.getChatMessages(
        chatId: widget.chatId,
        before: loadMore ? _nextBefore : null,
        limit: 30,
        userNo: _currentUserNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final List<dynamic> fetchedMessages = data['messages'] ?? [];
        final reversedFetched = fetchedMessages.reversed.toList();

        setState(() {
          _chatInfo = data['chat'];

          if (loadMore) {
            _hasMore = data['hasMore'] ?? false;
            _nextBefore = data['nextBefore'];
            _messages.addAll(reversedFetched);
          } else if (isAutoRefresh && _messages.isNotEmpty) {
            // 智慧合併：避免洗掉舊訊息，並修復收回後缺作者資訊的問題
            for (var fetchedMsg in reversedFetched) {
              final existingIndex = _messages.indexWhere((m) => m['messageId'] == fetchedMsg['messageId']);
              if (existingIndex != -1) {
                final oldMsg = _messages[existingIndex];
                // 若後端回傳的 recalled 訊息沒有 authorNo，就沿用本地原本的，防止氣泡跑位
                if (fetchedMsg['type'] == 'recalled' && (fetchedMsg['authorNo'] == null || fetchedMsg['authorNo'] == '')) {
                  fetchedMsg['authorNo'] = oldMsg['authorNo'];
                  fetchedMsg['authorName'] = oldMsg['authorName'];
                }
                _messages[existingIndex] = fetchedMsg;
              } else {
                _messages.insert(0, fetchedMsg);
              }
            }
          } else {
            _hasMore = data['hasMore'] ?? false;
            _nextBefore = data['nextBefore'];
            _messages = reversedFetched;
          }
        });
      }
    } catch (e) {
      debugPrint('[ParentChatRoom] 載入訊息失敗: $e');
    } finally {
      if (mounted && !isAutoRefresh) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatMessageTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(timeStr);
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return timeStr.substring(11, 16);
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      final res = await AuthService.sendChatMessage(
        chatId: widget.chatId,
        text: text,
        userNo: _currentUserNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (res['success'] == true && res['data'] != null) {
        _textController.clear();
        setState(() {
          _messages.insert(0, res['data']);
        });

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['msg'] ?? '發送失敗')),
          );
        }
      }
    } catch (e) {
      debugPrint('[ParentChatRoom] 發送訊息發生異常: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  // 👇 新增：收回訊息邏輯，確保收回後氣泡不會亂跳
  Future<void> _recallMessage(String? messageId) async {
    if (messageId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P'; // 家長端為 P

      final res = await AuthService.recallChatMessage(
        chatId: widget.chatId,
        messageId: messageId,
        userNo: _currentUserNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        setState(() {
          // 找到該筆訊息並更新為收回狀態
          final index = _messages.indexWhere((m) => m['messageId'] == messageId);
          if (index != -1) {
            // 取出舊訊息的作者資訊，強制塞給新訊息，避免後端漏給導致氣泡跑到左側
            final oldMsg = _messages[index];
            final newMsg = Map<String, dynamic>.from(res['data']);

            newMsg['authorNo'] = oldMsg['authorNo'];
            newMsg['authorName'] = oldMsg['authorName'];

            _messages[index] = newMsg;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['msg'] ?? '收回失敗')),
        );
      }
    } catch (e) {
      debugPrint('[ParentChatRoom] 收回訊息發生異常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('收回發生異常，請檢查網路')),
        );
      }
    }
  }

  Future<void> _showImagePickerModal() async {
    if (_isSending) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF6C63FF)),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF00B074)),
                title: const Text('從相簿選取'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isSending = true);

      final prefs = await SharedPreferences.getInstance();
      final xApiKey = prefs.getString('x_api_key') ?? prefs.getString('xApiKey') ?? '';
      final roleCode = prefs.getString('role_code') ?? 'P';

      final res = await AuthService.sendChatImageMessage(
        chatId: widget.chatId,
        filePath: pickedFile.path,
        userNo: _currentUserNo,
        xApiKey: xApiKey,
        roleCode: roleCode,
      );

      if (!mounted) return;

      if (res['success'] == true && res['data'] != null) {
        setState(() {
          _messages.insert(0, res['data']);
        });

        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['msg'] ?? '圖片發送失敗')),
        );
      }
    } catch (e) {
      debugPrint('[ParentChatRoom] 圖片選取或發送異常: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String? _extractFirstUrl(String text) {
    final RegExp urlRegExp = RegExp(
        r"((https?:www\.)|(https?:\/\/)|(www\.))[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9]{1,6}(\/[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)?");
    final match = urlRegExp.firstMatch(text);
    return match?.group(0);
  }

  Widget _buildMessageContent(Map<String, dynamic> msg, {required bool isMe}) {
    final type = msg['type'] ?? 'text';

    if (type == 'image') {
      String imageUrl = msg['resourceUri'] ?? '';
      if (imageUrl.startsWith('~')) {
        imageUrl = AuthService.baseUrl + imageUrl.substring(1);
      } else if (!imageUrl.startsWith('http')) {
        imageUrl = AuthService.baseUrl + imageUrl;
      }

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (fullscreenContext) => Scaffold(
                backgroundColor: Colors.black,
                appBar: PreferredSize(
                  preferredSize: Size.fromHeight(80.h),
                  child: Builder(
                      builder: (BuildContext innerContext) {
                        return AppBar(
                          backgroundColor: Colors.black,
                          elevation: 0,
                          toolbarHeight: 80.h,
                          leading: Center(
                            child: IconButton(
                              padding: EdgeInsets.all(8.w),
                              iconSize: 30.sp,
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          actions: [
                            IconButton(
                              padding: EdgeInsets.all(8.w),
                              iconSize: 30.sp,
                              icon: const Icon(Icons.download, color: Colors.white),
                              tooltip: '下載圖片',
                              onPressed: () {
                                ImageDownloadUtil.saveImageToGallery(innerContext, imageUrl);
                              },
                            ),
                            SizedBox(width: 16.w),
                          ],
                        );
                      }
                  ),
                ),
                body: SafeArea(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      clipBehavior: Clip.none,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 150.w,
                height: 150.w,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.grey),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 150.w,
                height: 150.w,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      );
    } else if (type == 'recalled') {
      return Text(
        msg['text'] ?? '訊息已收回',
        style: TextStyle(
          color: isMe ? Colors.white70 : Colors.black54,
          fontSize: 14.sp,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final text = msg['text'] ?? '';
    final url = _extractFirstUrl(text);

    if (url != null) {
      return Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15.sp,
              height: 1.4,
            ),
          ),
          GestureDetector(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.inAppBrowserView,
                );
              } else {
                debugPrint('無法開啟網址: $url');
              }
            },
            child: CustomLinkPreviewWidget(url: url, isMe: isMe),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        // 依據截圖，自己發送(家長)為白色，老師發送為深黑色
        color: isMe ? Colors.white : const Color(0xFF1E1E1E),
        fontSize: 15.sp,
        height: 1.4,
      ),
    );
  }

  // 👇 修改：加入 isMe 判斷，將刪除改為收回邏輯
  void _showTextOptions(BuildContext context, Map<String, dynamic> msg, {required bool isMe}) {
    if (msg['type'] == 'recalled') return; // 已收回的訊息禁用長按

    final bool isText = msg['type'] == 'text' || msg['type'] == null;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isText) // 只有純文字才顯示複製
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.black54),
                  title: const Text('複製文字'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已複製到剪貼簿'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
              if (isMe) // 只有自己發的才允許收回
                ListTile(
                  leading: const Icon(Icons.settings_backup_restore, color: Colors.red),
                  title: const Text('收回訊息', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context); // 先關閉選單
                    await _recallMessage(msg['messageId']);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC), // 依據截圖的超淡灰藍色底
      resizeToAvoidBottomInset: false,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              itemCount: _messages.length + (_isLoading && !_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Color(0xFF4A90E2)),
                    ),
                  );
                }

                final msg = _messages[index];
                final isMe = msg['authorNo'] == _currentUserNo;

                return isMe ? _buildMyMessage(msg) : _buildOtherMessage(msg);
              },
            ),
          ),
          _buildBottomInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F8FC),
      elevation: 0,
      toolbarHeight: 70.h,
      leading: Center(
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 24.sp,
            color: Colors.black54,
          ),
          onPressed: () => Navigator.pop(context, true),
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: widget.themeColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: const Icon(Icons.people_alt, color: Colors.white),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.chatName,
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                if (widget.subTitle.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    widget.subTitle,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 依據截圖：家長自己發出的訊息 (右側，藍底白字，右下角尖角)
  Widget _buildMyMessage(Map<String, dynamic> msg) {
    final bool isImage = msg['type'] == 'image';
    final screenWidth = MediaQuery.of(context).size.width;
    final isPad = screenWidth > 600;
    final bubbleMaxWidth = isPad ? 450.0 : screenWidth * 0.75;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 👇 修改：加入 onLongPress 觸發選單
          GestureDetector(
            onLongPress: () => _showTextOptions(context, msg, isMe: true),
            child: Container(
              constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
              padding: isImage ? EdgeInsets.all(4.w) : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2), // 截圖中的亮藍色
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18.r),
                  topRight: Radius.circular(18.r),
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: const Radius.circular(4), // 右下直角
                ),
              ),
              child: _buildMessageContent(msg, isMe: true),
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatMessageTime(msg['createdAt']),
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFFA0AAB4)),
              ),
              SizedBox(width: 4.w),
              Icon(Icons.done_all, size: 14.sp, color: const Color(0xFFA0AAB4)), // 雙勾符號
            ],
          ),
        ],
      ),
    );
  }

  // 依據截圖：老師發出的訊息 (左側，白底黑字，淡邊框，左下角尖角，加上圓形頭像)
  Widget _buildOtherMessage(Map<String, dynamic> msg) {
    final bool isImage = msg['type'] == 'image';
    final screenWidth = MediaQuery.of(context).size.width;
    final isPad = screenWidth > 600;
    final bubbleMaxWidth = isPad ? 450.0 : screenWidth * 0.7;

    // 依據作者名稱給予不同顏色的圓形頭像 (截圖中有紫色、綠色)
    final authorName = msg['authorName'] ?? '師';
    final avatarChar = authorName.substring(0, 1);
    final avatarColor = (avatarChar.hashCode % 2 == 0) ? const Color(0xFF6C63FF) : const Color(0xFF00B074);

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左側頭像
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarChar,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.sp),
            ),
          ),
          SizedBox(width: 8.w),
          // 訊息主體
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
                  child: Text(
                    msg['authorName'] ?? '',
                    style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey),
                  ),
                ),
                // 👇 修改：加入 onLongPress 觸發選單
                GestureDetector(
                  onLongPress: () => _showTextOptions(context, msg, isMe: false),
                  child: Container(
                    constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
                    padding: isImage ? EdgeInsets.all(4.w) : EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.r),
                        topRight: Radius.circular(18.r),
                        bottomRight: Radius.circular(18.r),
                        bottomLeft: const Radius.circular(4), // 左下直角
                      ),
                      border: Border.all(color: const Color(0xFFE2E8F0)), // 淡淡的邊框
                    ),
                    child: _buildMessageContent(msg, isMe: false),
                  ),
                ),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Text(
                    _formatMessageTime(msg['createdAt']),
                    style: TextStyle(fontSize: 11.sp, color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 底部輸入區域 (包含圖片按鈕、圓角輸入框、右側發送按鈕)
  Widget _buildBottomInputArea() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      color: const Color(0xFFF8F8FC),
      padding: EdgeInsets.only(
        top: 10.h,
        bottom: keyboardHeight > 0
            ? keyboardHeight + 10.h
            : bottomPadding + 10.h,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 圖片選擇按鈕
                GestureDetector(
                  onTap: _isSending ? null : _showImagePickerModal,
                  child: Padding(
                    padding: EdgeInsets.only(right: 12.w, bottom: 8.h),
                    child: Icon(
                      Icons.add_photo_alternate,
                      color: const Color(0xFF94A3B8),
                      size: 30.sp,
                    ),
                  ),
                ),
                // 圓角輸入框
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            style: TextStyle(fontSize: 15.sp),
                            decoration: InputDecoration(
                              hintText: '輸入訊息...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 15.sp),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Icon(Icons.sentiment_satisfied_alt, color: Colors.grey.shade500, size: 24.sp),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // 發送按鈕
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? SizedBox(
                        width: 24.sp,
                        height: 24.sp,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF94A3B8),
                        ),
                      )
                          : Icon(Icons.send, color: const Color(0xFF94A3B8), size: 24.sp),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}