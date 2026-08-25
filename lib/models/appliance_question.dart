/// POST /api/reports/analyze 응답의 appliance.questions 항목.
/// 가전 하자의 부담 주체(judgeAppliance)를 판정하기 전에 답해야 하는 보충
/// 질문이다 — ownership(소유 관계)을 먼저 묻고, 필요하면 purchase_age(사용
/// 연차)를 이어서 묻는다(reports.controller.ts의 nextApplianceQuestions).
class ApplianceQuestion {
  final String id;
  final String text;
  final List<ApplianceOption> options;

  ApplianceQuestion({required this.id, required this.text, required this.options});

  factory ApplianceQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List?;
    return ApplianceQuestion(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      options: (rawOptions ?? const [])
          .map((o) => ApplianceOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApplianceOption {
  final String value;
  final String label;

  ApplianceOption({required this.value, required this.label});

  factory ApplianceOption.fromJson(Map<String, dynamic> json) {
    return ApplianceOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
