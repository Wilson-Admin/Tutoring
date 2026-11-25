class AdminSurveyStatisticsResponse {
  final bool success;
  final String msg;
  final AdminSurveyStatisticsData? data;

  AdminSurveyStatisticsResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory AdminSurveyStatisticsResponse.fromJson(Map<String, dynamic> json) {
    return AdminSurveyStatisticsResponse(
      success: json['success'] ?? false,
      msg: json['msg']?.toString() ?? '',
      data: json['data'] != null
          ? AdminSurveyStatisticsData.fromJson(json['data'])
          : null,
    );
  }
}

class AdminSurveyStatisticsData {
  final String surveyNo;
  final String title;
  final SurveyStatSummary summary;
  final List<SurveyStatQuestion> questions;
  final List<SurveyRespondent> respondents;

  AdminSurveyStatisticsData({
    required this.surveyNo,
    required this.title,
    required this.summary,
    required this.questions,
    required this.respondents,
  });

  factory AdminSurveyStatisticsData.fromJson(Map<String, dynamic> json) {
    final qList = json['questions'] as List? ?? [];
    final rList = json['respondents'] as List? ?? [];
    return AdminSurveyStatisticsData(
      surveyNo: json['surveyNo']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: SurveyStatSummary.fromJson(json['summary'] ?? {}),
      questions: qList.map((e) => SurveyStatQuestion.fromJson(e)).toList(),
      respondents: rList.map((e) => SurveyRespondent.fromJson(e)).toList(),
    );
  }
}

class SurveyStatSummary {
  final int targetCount;
  final int successCount;
  final int failCount;
  final int responseCount;
  final int notResponseCount;
  final double responseRate;

  SurveyStatSummary({
    required this.targetCount,
    required this.successCount,
    required this.failCount,
    required this.responseCount,
    required this.notResponseCount,
    required this.responseRate,
  });

  factory SurveyStatSummary.fromJson(Map<String, dynamic> json) {
    return SurveyStatSummary(
      targetCount: json['targetCount'] ?? 0,
      successCount: json['successCount'] ?? 0,
      failCount: json['failCount'] ?? 0,
      responseCount: json['responseCount'] ?? 0,
      notResponseCount: json['notResponseCount'] ?? 0,
      responseRate: (json['responseRate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SurveyStatQuestion {
  final int questionSr;
  final String question;
  final List<SurveyStatOption> options;

  SurveyStatQuestion({
    required this.questionSr,
    required this.question,
    required this.options,
  });

  factory SurveyStatQuestion.fromJson(Map<String, dynamic> json) {
    final optList = json['options'] as List? ?? [];
    return SurveyStatQuestion(
      questionSr: json['questionSr'] ?? 0,
      question: json['question']?.toString() ?? '',
      options: optList.map((e) => SurveyStatOption.fromJson(e)).toList(),
    );
  }
}

class SurveyStatOption {
  final int optionSr;
  final String optionText;
  final int count;
  final double rate;

  SurveyStatOption({
    required this.optionSr,
    required this.optionText,
    required this.count,
    required this.rate,
  });

  factory SurveyStatOption.fromJson(Map<String, dynamic> json) {
    return SurveyStatOption(
      optionSr: (json['optionSr'] as num?)?.toInt() ?? 0,
      optionText: json['optionText']?.toString() ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'optionSr': optionSr,
    'optionText': optionText,
    'count': count,
    'rate': rate,
  };
}

class SurveyRespondent {
  final String csNo;
  final String studentNm;
  final int classNo;
  final String classNm;
  final String parentNo;
  final String parentNm;
  final String responseAt;

  SurveyRespondent({
    required this.csNo,
    required this.studentNm,
    required this.classNo,
    required this.classNm,
    required this.parentNo,
    required this.parentNm,
    required this.responseAt,
  });

  factory SurveyRespondent.fromJson(Map<String, dynamic> json) {
    return SurveyRespondent(
      csNo: json['csNo']?.toString() ?? '',
      studentNm: json['studentNm']?.toString() ?? '',
      classNo: json['classNo'] ?? 0,
      classNm: json['classNm']?.toString() ?? '',
      parentNo: json['parentNo']?.toString() ?? '',
      parentNm: json['parentNm']?.toString() ?? '',
      responseAt: json['responseAt']?.toString() ?? '',
    );
  }
}