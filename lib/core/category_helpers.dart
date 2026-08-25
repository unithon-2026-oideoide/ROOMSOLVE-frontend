import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 카테고리 영문 코드 ↔ 한글 명칭 매핑.
/// 백엔드 REPAIR_CATEGORIES(src/types/index.ts) 및 AI 분석 카테고리와 일치.
const Map<String, String> categoryLabels = {
  'plumbing': '배관·누수',
  'electrical': '전기·조명',
  'heating': '냉난방',
  'appliance': '가전',
  'door_window': '문·창문',
  'interior': '인테리어',
  'pest': '해충 방역',
  'other': '기타',
};

/// 긴급도(severity) 영문 코드 ↔ 한글 명칭 매핑.
const Map<String, String> severityLabels = {
  'low': '경미',
  'medium': '보통',
  'high': '심각',
  'emergency': '긴급',
};

/// 수리 요청 상태 영문 코드 ↔ 한글 명칭 매핑.
const Map<String, String> requestStatusLabels = {
  'pending': '승인 대기',
  'approved': '승인됨',
  'rejected': '거절됨',
  'in_progress': '진행 중',
  'completed': '완료',
  'done': '완료',
};

/// 영문 카테고리 키를 친절한 한글 라벨로 변환한다.
/// 이미 한글이거나 매핑에 없으면 fallback을 제공한다.
String categoryLabel(String? category, {String fallback = '미분류'}) {
  if (category == null || category.trim().isEmpty) return fallback;
  final key = category.trim().toLowerCase();
  return categoryLabels[key] ?? category;
}

/// 영문 긴급도 키를 친절한 한글 라벨로 변환한다.
String severityLabel(String? severity, {String fallback = '보통'}) {
  if (severity == null || severity.trim().isEmpty) return fallback;
  final key = severity.trim().toLowerCase();
  return severityLabels[key] ?? severity;
}

/// 영문 수리 요청 상태를 한글 라벨로 변환한다.
String requestStatusLabel(String? status, {String fallback = '승인 대기'}) {
  if (status == null || status.trim().isEmpty) return fallback;
  final key = status.trim().toLowerCase();
  return requestStatusLabels[key] ?? status;
}

/// 수리 요청 상태에 따른 배지 배경 색상.
Color requestStatusColor(String? status) {
  final key = status?.trim().toLowerCase() ?? '';
  switch (key) {
    case 'pending':
      return AppColors.accentGreen;
    case 'approved':
    case 'in_progress':
      return AppColors.brandMain;
    case 'rejected':
      return AppColors.accentRed;
    case 'completed':
    case 'done':
      return AppColors.gray5;
    default:
      if (key.contains('대기')) return AppColors.accentGreen;
      if (key.contains('진행') || key.contains('승인')) return AppColors.brandMain;
      if (key.contains('거절')) return AppColors.accentRed;
      if (key.contains('완료')) return AppColors.gray5;
      return AppColors.accentGreen;
  }
}

/// repair_status_timeline.status(scheduled/confirmed/in_progress/done) 영문
/// 코드 ↔ 한글 명칭 매핑. requestStatusLabels(reports.status)와는 값의 종류가
/// 다른 별개 축이다 — 섞어 쓰지 말 것.
const Map<String, String> repairStatusLabels = {
  'scheduled': '방문 일정 등록',
  'confirmed': '방문 일정 확정',
  'in_progress': '현장 수리 진행 중',
  'done': '수리 완료',
};

/// GET /api/repair/timeline·schedule이 주는 영문 상태를 한글 라벨로 변환한다.
/// report_detail_screen.dart와 report_progress_screen.dart가 공유해서 쓴다 —
/// 예전에는 report_detail_screen.dart에만 이 변환기(_repairStatusLabel)가 있고
/// report_progress_screen.dart는 없어서, 같은 신고를 두 화면에서 볼 때 한쪽은
/// "현장 수리 진행 중", 다른 쪽은 원문 그대로 "in_progress"가 보이는 문제가 있었다.
String repairStatusLabel(String? status) {
  if (status == null || status.trim().isEmpty) return '진행 중';
  final key = status.trim().toLowerCase();
  return repairStatusLabels[key] ?? status;
}

/// ISO 날짜 문자열을 읽기 쉬운 한글 날짜/시간으로 포맷팅한다.
String formatDateTime(String? isoString, {String fallback = '-'}) {
  if (isoString == null || isoString.trim().isEmpty) return fallback;
  final dt = DateTime.tryParse(isoString.trim());
  if (dt == null) return isoString;
  final local = dt.toLocal();
  return '${local.year}년 ${local.month}월 ${local.day}일 ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// 수리 요청 목록(Map)의 메인 타이틀을 생성한다.
/// 우선순위:
/// 1. title 필드가 직접 지정되어 있으면 사용
/// 2. category가 있으면 한글 카테고리명 (예: "인테리어 수리 요청")
/// 3. description이 있으면 첫 줄 요약
/// 4. '수리 요청 #${id}'
String formatRequestTitle(Map<String, dynamic> request) {
  final title = request['title']?.toString().trim();
  if (title != null && title.isNotEmpty) return title;

  final cat = request['category']?.toString().trim();
  if (cat != null && cat.isNotEmpty) {
    final catKor = categoryLabel(cat);
    return '$catKor 수리 요청';
  }

  final desc = request['description']?.toString().trim();
  if (desc != null && desc.isNotEmpty) {
    final firstLine = desc.split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
  }

  final id = request['id']?.toString();
  return id != null && id.isNotEmpty ? '수리 요청 #$id' : '수리 요청';
}

/// 수리 요청 목록(Map)의 서브타이틀(호실/위치/상세 설명 요약)을 생성한다.
String formatRequestSubtitle(Map<String, dynamic> request) {
  final unit = request['unit']?.toString().trim() ?? request['location']?.toString().trim() ?? '';
  final desc = request['description']?.toString().trim() ?? '';

  if (unit.isNotEmpty && desc.isNotEmpty) {
    return '$unit · $desc';
  }
  if (desc.isNotEmpty) return desc;
  if (unit.isNotEmpty) return unit;
  return '';
}

/// Report 모델용 타이틀 생성 헬퍼
String formatReportTitle(String? category, String? description, {String fallback = '수리 요청'}) {
  if (category != null && category.trim().isNotEmpty) {
    final catKor = categoryLabel(category);
    return '$catKor 수리 요청';
  }
  if (description != null && description.trim().isNotEmpty) {
    final firstLine = description.split('\n').first.trim();
    if (firstLine.isNotEmpty) return firstLine;
  }
  return fallback;
}
