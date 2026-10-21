class ChatListResponse {
  final bool success;
  final String msg;
  final ChatListData? data;

  ChatListResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory ChatListResponse.fromJson(Map<String, dynamic> json) {
    return ChatListResponse(
      success: json['success'] == true,
      msg: json['msg']?.toString() ?? '',
      data: json['data'] != null ? ChatListData.fromJson(json['data']) : null,
    );
  }
}

class ChatListData {
  final List<ChatItem> chats;
  final List<SchoolInfo> schools;
  final List<ClassInfo> classes;
  final List<CourseInfo> courses;
  final int total;
  final int unreadTotal;

  ChatListData({
    required this.chats,
    required this.schools,
    required this.classes,
    required this.courses,
    required this.total,
    required this.unreadTotal,
  });

  factory ChatListData.fromJson(Map<String, dynamic> json) {
    return ChatListData(
      chats: (json['chats'] as List<dynamic>?)
          ?.map((e) => ChatItem.fromJson(e))
          .toList() ??
          [],
      schools: (json['schools'] as List<dynamic>?)
          ?.map((e) => SchoolInfo.fromJson(e))
          .toList() ??
          [],
      classes: (json['classes'] as List<dynamic>?)
          ?.map((e) => ClassInfo.fromJson(e))
          .toList() ??
          [],
      courses: (json['courses'] as List<dynamic>?)
          ?.map((e) => CourseInfo.fromJson(e))
          .toList() ??
          [],
      total: json['total'] is int ? json['total'] : int.tryParse('${json['total']}') ?? 0,
      unreadTotal: json['unreadTotal'] is int
          ? json['unreadTotal']
          : int.tryParse('${json['unreadTotal']}') ?? 0,
    );
  }
}

class ChatItem {
  final String chatId;
  final String csNo;
  final String studentNm;
  final int classNo;
  final String classNm;
  final String depmNo;
  final String lastMessage;
  final List<String> courseNos;
  final String lastMessageAt;
  int unreadCount;

  ChatItem({
    required this.chatId,
    required this.csNo,
    required this.studentNm,
    required this.classNo,
    required this.classNm,
    required this.depmNo,
    required this.lastMessage,
    required this.courseNos,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatItem.fromJson(Map<String, dynamic> json) {
    return ChatItem(
      chatId: json['chatId']?.toString() ?? '',
      csNo: json['csNo']?.toString() ?? '',
      studentNm: json['studentNm']?.toString() ?? '',
      classNo: json['classNo'] is int ? json['classNo'] : int.tryParse('${json['classNo']}') ?? 0,
      classNm: json['classNm']?.toString() ?? '',
      depmNo: json['depmNo']?.toString() ?? '',
      lastMessage: json['lastMessage']?.toString() ?? '',
      courseNos: (json['courseNos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      lastMessageAt: json['lastMessageAt']?.toString() ?? '',
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount']
          : int.tryParse('${json['unreadCount']}') ?? 0,
    );
  }
}

class SchoolInfo {
  final String depmNo;
  final String depmNm;

  SchoolInfo({required this.depmNo, required this.depmNm});

  factory SchoolInfo.fromJson(Map<String, dynamic> json) {
    return SchoolInfo(
      depmNo: json['depmNo']?.toString() ?? '',
      depmNm: json['depmNm']?.toString() ?? '',
    );
  }
}

class ClassInfo {
  final int classNo;
  final String classNm;
  final String depmNo;

  ClassInfo({
    required this.classNo,
    required this.classNm,
    required this.depmNo,
  });

  factory ClassInfo.fromJson(Map<String, dynamic> json) {
    return ClassInfo(
      classNo: json['classNo'] is int ? json['classNo'] : int.tryParse('${json['classNo']}') ?? 0,
      classNm: json['classNm']?.toString() ?? '',
      depmNo: json['depmNo']?.toString() ?? '',
    );
  }
}

class CourseInfo {
  final String courseNo;
  final String courseNm;
  final String depmNo;

  CourseInfo({
    required this.courseNo,
    required this.courseNm,
    required this.depmNo,
  });

  factory CourseInfo.fromJson(Map<String, dynamic> json) {
    return CourseInfo(
      courseNo: json['courseNo']?.toString() ?? '',
      courseNm: json['courseNm']?.toString() ?? '',
      depmNo: json['depmNo']?.toString() ?? '',
    );
  }
}