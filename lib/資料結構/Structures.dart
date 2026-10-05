class LoginResponse {
  final bool success;
  final String msg;
  final LoginData? data;

  LoginResponse({
    required this.success,
    required this.msg,
    this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      msg: json['msg'] ?? '',
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
    );
  }
}

class LoginData {
  final String userNo;
  final String userNm;
  final String picLink;
  final String signLink;
  final String fcm;
  final String xApiKey;
  final List<SchoolRole> schools;

  LoginData({
    required this.userNo,
    required this.userNm,
    required this.picLink,
    required this.signLink,
    required this.fcm,
    required this.xApiKey,
    required this.schools,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      userNo: json['userNo'] ?? '',
      userNm: json['userNm'] ?? '',
      picLink: json['picLink'] ?? '',
      signLink: json['signLink'] ?? '',
      fcm: json['fcm'] ?? '',
      xApiKey: json['xApiKey'] ?? '',
      schools: (json['schools'] as List<dynamic>?)
          ?.map((e) => SchoolRole.fromJson(e))
          .toList() ??
          [],
    );
  }

  /// 判斷是否包含家長身分 (M)
  bool get hasParentRole => schools.any((s) => s.roleCode == 'M');

  /// 判斷是否包含教師/職員身分 (T, P, A, S 等非 M)
  bool get hasTeacherRole => schools.any((s) => s.roleCode != 'M');

  /// 判斷是否同時具備多重角色
  bool get hasMultipleRoles => hasParentRole && hasTeacherRole;
}

class SchoolRole {
  final String depmNo;
  final String depmNm;
  final String roleCode;

  SchoolRole({
    required this.depmNo,
    required this.depmNm,
    required this.roleCode,
  });

  factory SchoolRole.fromJson(Map<String, dynamic> json) {
    return SchoolRole(
      depmNo: json['depmNo'] ?? '',
      depmNm: json['depmNm'] ?? '',
      roleCode: json['roleCode'] ?? '',
    );
  }
}