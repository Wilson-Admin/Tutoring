class StudentListResponse {
  final bool success;
  final String msg;
  final StudentListData? data;

  StudentListResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory StudentListResponse.fromJson(Map<String, dynamic> json) {
    return StudentListResponse(
      success: json['success'] == true,
      msg: json['msg']?.toString() ?? '',
      data: json['data'] != null ? StudentListData.fromJson(json['data']) : null,
    );
  }
}

class StudentListData {
  final List<StudentItem> items;
  final List<SchoolItem> schools;
  final List<CourseItem> courses;
  final int total;

  StudentListData({
    required this.items,
    required this.schools,
    required this.courses,
    required this.total,
  });

  factory StudentListData.fromJson(Map<String, dynamic> json) {
    return StudentListData(
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => StudentItem.fromJson(e))
          .toList() ??
          [],
      schools: (json['schools'] as List<dynamic>?)
          ?.map((e) => SchoolItem.fromJson(e))
          .toList() ??
          [],
      courses: (json['courses'] as List<dynamic>?)
          ?.map((e) => CourseItem.fromJson(e))
          .toList() ??
          [],
      total: json['total'] is int ? json['total'] : 0,
    );
  }
}

class StudentItem {
  final String csNo;
  final String csNm;
  final int classNo;
  final String classNm;
  final String depmNo;
  final String studentPicLink;
  final String chatId;
  final List<String> courseNos;

  StudentItem({
    required this.csNo,
    required this.csNm,
    required this.classNo,
    required this.classNm,
    required this.depmNo,
    required this.studentPicLink,
    required this.chatId,
    required this.courseNos,
  });

  factory StudentItem.fromJson(Map<String, dynamic> json) {
    return StudentItem(
      csNo: json['csNo']?.toString() ?? '',
      csNm: json['csNm']?.toString() ?? '',
      classNo: json['classNo'] is int ? json['classNo'] : int.tryParse('${json['classNo']}') ?? 0,
      classNm: json['classNm']?.toString() ?? '',
      depmNo: json['depmNo']?.toString() ?? '',
      studentPicLink: json['studentPicLink']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      courseNos: (json['courseNos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
    );
  }
}

class SchoolItem {
  final String depmNo;
  final String depmNm;

  SchoolItem({required this.depmNo, required this.depmNm});

  factory SchoolItem.fromJson(Map<String, dynamic> json) {
    return SchoolItem(
      depmNo: json['depmNo']?.toString() ?? '',
      depmNm: json['depmNm']?.toString() ?? '',
    );
  }
}

class CourseItem {
  final String courseNo;
  final String courseNm;
  final String depmNo;
  final String teacherNm;

  CourseItem({
    required this.courseNo,
    required this.courseNm,
    required this.depmNo,
    required this.teacherNm,
  });

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      courseNo: json['courseNo']?.toString() ?? '',
      courseNm: json['courseNm']?.toString() ?? '',
      depmNo: json['depmNo']?.toString() ?? '',
      teacherNm: json['teacherNm']?.toString() ?? '',
    );
  }
}