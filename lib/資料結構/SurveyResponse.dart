class SurveyResponse {
  final bool success;
  final String msg;
  final SurveyData? data;

  SurveyResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory SurveyResponse.fromJson(Map<String, dynamic> json) {
    return SurveyResponse(
      success: json['success'] ?? false,
      msg: json['msg'] ?? '',
      data: json['data'] != null ? SurveyData.fromJson(json['data']) : null,
    );
  }
}

class SurveyData {
  final List<SurveyItem> items;
  final SurveySummary? summary;

  SurveyData({
    required this.items,
    this.summary,
  });

  factory SurveyData.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] as List? ?? [];
    List<SurveyItem> items = itemList.map((i) => SurveyItem.fromJson(i)).toList();

    return SurveyData(
      items: items,
      summary: json['summary'] != null ? SurveySummary.fromJson(json['summary']) : null,
    );
  }
}

class SurveyItem {
  final String surveyNo;
  final String csNo;
  final String csNm;
  final String title;
  final String detail;
  final String startDate;
  final String endDate;
  final bool answered;
  final String? responseAt;

  SurveyItem({
    required this.surveyNo,
    required this.csNo,
    required this.csNm,
    required this.title,
    required this.detail,
    required this.startDate,
    required this.endDate,
    required this.answered,
    this.responseAt,
  });

  factory SurveyItem.fromJson(Map<String, dynamic> json) {
    return SurveyItem(
      surveyNo: json['surveyNo'] ?? '',
      csNo: json['csNo'] ?? '',
      csNm: json['csNm'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      answered: json['answered'] ?? false,
      responseAt: json['responseAt'],
    );
  }
}

class SurveySummary {
  final int total;
  final int unansweredCount;
  final int answeredCount;

  SurveySummary({
    required this.total,
    required this.unansweredCount,
    required this.answeredCount,
  });

  factory SurveySummary.fromJson(Map<String, dynamic> json) {
    return SurveySummary(
      total: json['total'] ?? 0,
      unansweredCount: json['unansweredCount'] ?? 0,
      answeredCount: json['answeredCount'] ?? 0,
    );
  }
}