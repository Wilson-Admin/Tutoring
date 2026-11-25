class AdminSurveyListResponse {
  final bool success;
  final String msg;
  final AdminSurveyListData? data;

  AdminSurveyListResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory AdminSurveyListResponse.fromJson(Map<String, dynamic> json) {
    return AdminSurveyListResponse(
      success: json['success'] ?? false,
      msg: json['msg']?.toString() ?? '',
      data: json['data'] != null
          ? AdminSurveyListData.fromJson(json['data'])
          : null,
    );
  }
}

class AdminSurveyListData {
  final List<AdminSurveyItem> items;
  final int total;

  AdminSurveyListData({
    required this.items,
    required this.total,
  });

  factory AdminSurveyListData.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return AdminSurveyListData(
      items: list.map((e) => AdminSurveyItem.fromJson(e)).toList(),
      total: json['total'] ?? 0,
    );
  }
}

class AdminSurveyItem {
  final String surveyNo;
  final String title;
  final String detail;
  final String surveyType; // 例如：A (全校), C (班級)
  final String? startDate;
  final String? endDate;
  final String status; // 例如：Y (進行中), S (草稿)
  final int questionCount;
  final int sentCount;
  final int responseCount;
  final String addUser;
  final String addDate;

  AdminSurveyItem({
    required this.surveyNo,
    required this.title,
    required this.detail,
    required this.surveyType,
    this.startDate,
    this.endDate,
    required this.status,
    required this.questionCount,
    required this.sentCount,
    required this.responseCount,
    required this.addUser,
    required this.addDate,
  });

  factory AdminSurveyItem.fromJson(Map<String, dynamic> json) {
    return AdminSurveyItem(
      surveyNo: json['surveyNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      surveyType: json['surveyType']?.toString() ?? '',
      startDate: json['startDate']?.toString(),
      endDate: json['endDate']?.toString(),
      status: json['status']?.toString() ?? '',
      questionCount: json['questionCount'] ?? 0,
      sentCount: json['sentCount'] ?? 0,
      responseCount: json['responseCount'] ?? 0,
      addUser: json['addUser']?.toString() ?? '',
      addDate: json['addDate']?.toString() ?? '',
    );
  }
}