class SurveyDetailResponse {
  final bool success;
  final String msg;
  final SurveyDetailData? data;

  SurveyDetailResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory SurveyDetailResponse.fromJson(Map<String, dynamic> json) {
    return SurveyDetailResponse(
      success: json['success'] ?? false,
      msg: json['msg'] ?? '',
      data: json['data'] != null ? SurveyDetailData.fromJson(json['data']) : null,
    );
  }
}

class SurveyDetailData {
  final String surveyNo;
  final String title;
  final String detail;
  final String startDate;
  final String? endDate;
  final SurveyStudent? student;
  final SurveyParent? parent;
  final String? responseAt;
  final List<SurveyQuestion> questions; // 未填寫時使用
  final List<SurveyAnswer> answers;     // 已填寫時使用

  SurveyDetailData({
    required this.surveyNo,
    required this.title,
    required this.detail,
    required this.startDate,
    this.endDate,
    this.student,
    this.parent,
    this.responseAt,
    required this.questions,
    required this.answers,
  });

  factory SurveyDetailData.fromJson(Map<String, dynamic> json) {
    var qList = json['questions'] as List? ?? [];
    List<SurveyQuestion> questions = qList.map((q) => SurveyQuestion.fromJson(q)).toList();

    var aList = json['answers'] as List? ?? [];
    List<SurveyAnswer> answers = aList.map((a) => SurveyAnswer.fromJson(a)).toList();

    return SurveyDetailData(
      surveyNo: json['surveyNo'] ?? '',
      title: json['title'] ?? '',
      detail: json['detail'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'],
      student: json['student'] != null ? SurveyStudent.fromJson(json['student']) : null,
      parent: json['parent'] != null ? SurveyParent.fromJson(json['parent']) : null,
      responseAt: json['responseAt'],
      questions: questions,
      answers: answers,
    );
  }
}

class SurveyStudent {
  final String csNo;
  final String csNm;
  final int classNo;
  final String classNm;

  SurveyStudent({
    required this.csNo,
    required this.csNm,
    required this.classNo,
    required this.classNm,
  });

  factory SurveyStudent.fromJson(Map<String, dynamic> json) {
    return SurveyStudent(
      csNo: json['csNo'] ?? '',
      csNm: json['csNm'] ?? '',
      classNo: json['classNo'] ?? 0,
      classNm: json['classNm'] ?? '',
    );
  }
}

class SurveyParent {
  final String parentNo;
  final String parentNm;

  SurveyParent({
    required this.parentNo,
    required this.parentNm,
  });

  factory SurveyParent.fromJson(Map<String, dynamic> json) {
    return SurveyParent(
      parentNo: json['parentNo'] ?? '',
      parentNm: json['parentNm'] ?? '',
    );
  }
}

class SurveyQuestion {
  final int questionSr;
  final String question;
  final List<SurveyOption> options;

  SurveyQuestion({
    required this.questionSr,
    required this.question,
    required this.options,
  });

  factory SurveyQuestion.fromJson(Map<String, dynamic> json) {
    var oList = json['options'] as List? ?? [];
    List<SurveyOption> options = oList.map((o) => SurveyOption.fromJson(o)).toList();

    return SurveyQuestion(
      questionSr: json['questionSr'] ?? 0,
      question: json['question'] ?? '',
      options: options,
    );
  }
}

class SurveyOption {
  final int optionSr;
  final String optionText;

  SurveyOption({
    required this.optionSr,
    required this.optionText,
  });

  factory SurveyOption.fromJson(Map<String, dynamic> json) {
    return SurveyOption(
      optionSr: json['optionSr'] ?? 0,
      optionText: json['optionText'] ?? '',
    );
  }
}

class SurveyAnswer {
  final int questionSr;
  final String question;
  final int optionSr;
  final String optionText;

  SurveyAnswer({
    required this.questionSr,
    required this.question,
    required this.optionSr,
    required this.optionText,
  });

  factory SurveyAnswer.fromJson(Map<String, dynamic> json) {
    return SurveyAnswer(
      questionSr: json['questionSr'] ?? 0,
      question: json['question'] ?? '',
      optionSr: json['optionSr'] ?? 0,
      optionText: json['optionText'] ?? '',
    );
  }
}