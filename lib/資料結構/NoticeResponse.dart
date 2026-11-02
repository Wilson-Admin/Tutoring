class NoticeResponse {
  final bool success;
  final String msg;
  final NoticeData? data;

  NoticeResponse({required this.success, required this.msg, this.data});

  factory NoticeResponse.fromJson(Map<String, dynamic> json) {
    return NoticeResponse(
      success: json['success'] ?? false,
      msg: json['msg'] ?? '',
      data: json['data'] != null ? NoticeData.fromJson(json['data']) : null,
    );
  }
}

class NoticeData {
  final List<NoticeItem> items;
  final NoticeGroups groups;
  final int total;

  NoticeData({required this.items, required this.groups, required this.total});

  factory NoticeData.fromJson(Map<String, dynamic> json) {
    return NoticeData(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => NoticeItem.fromJson(e))
          .toList() ??
          [],
      groups: NoticeGroups.fromJson(json['groups'] ?? {}),
      total: json['total'] ?? 0,
    );
  }
}

class NoticeGroups {
  final List<NoticeTypeGroup> noticeTypes;

  NoticeGroups({required this.noticeTypes});

  factory NoticeGroups.fromJson(Map<String, dynamic> json) {
    return NoticeGroups(
      noticeTypes: (json['noticeTypes'] as List<dynamic>?)
          ?.map((e) => NoticeTypeGroup.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class NoticeTypeGroup {
  final String code;
  final String name;
  final int count;

  NoticeTypeGroup({required this.code, required this.name, required this.count});

  factory NoticeTypeGroup.fromJson(Map<String, dynamic> json) {
    return NoticeTypeGroup(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      count: json['count'] ?? 0,
    );
  }
}

class NoticeItem {
  final String noticeNo;
  final String noticeType;
  final String title;
  final String detail;
  final String startDate;
  final String endDate;
  final String pinTop;
  final String popup;
  final List<NoticeFile> files;

  NoticeItem({
    required this.noticeNo,
    required this.noticeType,
    required this.title,
    required this.detail,
    required this.startDate,
    required this.endDate,
    required this.pinTop,
    required this.popup,
    required this.files,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      noticeNo: json['noticeNo'] ?? '',
      noticeType: json['noticeType'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      pinTop: json['pinTop'] ?? 'N',
      popup: json['popup'] ?? 'N',
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => NoticeFile.fromJson(e))
          .toList() ??
          [],
    );
  }
}

class NoticeFile {
  final int fileSr;
  final String fileType;
  final String fileName;
  final String fileLink;

  NoticeFile({
    required this.fileSr,
    required this.fileType,
    required this.fileName,
    required this.fileLink,
  });

  factory NoticeFile.fromJson(Map<String, dynamic> json) {
    return NoticeFile(
      fileSr: json['fileSr'] ?? 1,
      fileType: json['fileType'] ?? '',
      fileName: json['fileName'] ?? '',
      fileLink: json['fileLink'] ?? '',
    );
  }
}

class SingleNoticeResponse {
  final bool success;
  final String msg;
  final NoticeItem? data;

  SingleNoticeResponse({required this.success, required this.msg, this.data});

  factory SingleNoticeResponse.fromJson(Map<String, dynamic> json) {
    return SingleNoticeResponse(
      success: json['success'] ?? false,
      msg: json['msg'] ?? '',
      data: json['data'] != null ? NoticeItem.fromJson(json['data']) : null,
    );
  }
}