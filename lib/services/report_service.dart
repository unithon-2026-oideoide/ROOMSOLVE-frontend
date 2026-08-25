import 'dart:io';

import '../core/api_client.dart';
import '../models/appliance_question.dart';
import '../models/report.dart';
import '../models/vendor.dart';
import '../models/vendor_request.dart';

/// 사진 업로드(하나 이상)가 실패했을 때, 어떤 파일이 실패했는지 알 수 있도록
/// ApiException과 구분되는 전용 예외로 던진다.
class PhotoUploadException implements Exception {
  final String message;
  PhotoUploadException(this.message);

  @override
  String toString() => message;
}

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  final _api = ApiClient.instance;

  Future<List<Report>> getReports() async {
    final response = await _api.get('/api/reports');
    final data = response.data as Map<String, dynamic>;
    final list = (data['reports'] as List?) ?? [];
    return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Report> getReport(String id) async {
    final response = await _api.get('/api/reports/$id');
    final data = response.data as Map<String, dynamic>;
    return Report.fromJson(data['report'] as Map<String, dynamic>);
  }

  /// 신고를 실제로 저장한다(POST /api/reports). `landlordId`를 생략하면
  /// 백엔드가 로그인한 세입자의 linked_landlord_id(설정 > 임대인 연결에서 임대인
  /// 초대 코드를 입력해 저장된 값)를 대신 쓴다. 아직 어느 임대인과도 연결돼
  /// 있지 않고 landlordId도 안 주면 서버가 400을 준다 — 그 메시지를 그대로
  /// [ApiException]으로 화면에 보여주면 된다.
  Future<Report> createReport({
    required String description,
    required List<String> photoUrls,
    String? landlordId,
    String? category,
    String? severity,
    String? recommendedPath,
    String? selfFixGuide,
    String? applianceType,
    String? availableTimes,
  }) async {
    final response = await _api.post('/api/reports', data: {
      'landlord_id': ?landlordId,
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
      'category': ?category,
      'severity': ?severity,
      'recommended_path': ?recommendedPath,
      'self_fix_guide': ?selfFixGuide,
      'appliance_type': ?applianceType,
      'available_times': ?availableTimes,
    });
    final data = response.data as Map<String, dynamic>;
    return Report.fromJson(data['report'] as Map<String, dynamic>);
  }

  /// POST /api/reports/analyze. [answers]는 가전 하자의 보충 질문
  /// (ownership/purchase_age)에 대한 답 — 처음 호출할 때는 비워 두고, 응답의
  /// appliance.questions에 질문이 담겨 오면 답을 모아 채워서 다시 호출한다.
  Future<Map<String, dynamic>> analyze({
    required String description,
    required List<String> photoUrls,
    Map<String, String>? answers,
  }) async {
    final response = await _api.post('/api/reports/analyze', data: {
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
      if (answers != null && answers.isNotEmpty) 'answers': answers,
    });
    return response.data as Map<String, dynamic>;
  }

  /// 세입자의 신고 접수 플로우 전체(사진 업로드 → AI 분석 → [가전이면 보충 질문
  /// 응답] → DB 저장)를 한 번에 처리한다. report_additional_info_screen이
  /// "다음 단계로"에서 호출하는 유일한 진입점이다.
  ///
  /// landlord_id는 보내지 않는다 — createReport가 서버 쪽 linked_landlord_id로
  /// 채우게 둔다. 아직 임대인과 연결돼 있지 않으면 createReport 단계에서
  /// ApiException이 던져지는데, 메시지에 "설정에서 임대인 초대 코드를 먼저
  /// 입력"하라는 안내가 포함되어 있어 화면에 그대로 보여주면 된다.
  ///
  /// [availableTimes]는 세입자가 집에 있는 시간대(예: "평일 오후, 주말 오전").
  /// 업체가 방문 시간을 제안할 때 참고하는 값이라 AI 분석에는 넘기지 않고
  /// 저장만 한다.
  ///
  /// [onApplianceQuestion]은 analyze 응답이 가전 하자 보충 질문을 돌려줄 때마다
  /// 호출된다(ownership을 먼저 묻고, 필요하면 purchase_age를 이어서 묻는다 —
  /// 한 번에 최대 1개씩 온다). 화면이 다이얼로그 등으로 답을 받아 값을
  /// 돌려주면 그 답으로 analyze를 다시 호출해 판정을 이어간다. 콜백을 안 주면
  /// (질문에 답할 UI가 없으면) 판정 없이 저장해 안내가 틀리는 상황을 막기 위해
  /// 예외를 던진다.
  ///
  /// 판정이 끝나면(=liability가 채워지면) 부담 주체·근거·경고 문구를 description
  /// 끝에 덧붙여 저장한다 — reports 테이블에 이 판정을 담을 별도 컬럼이 없어서다
  /// (같은 화면의 "문제 발생 시점" 등 다른 보충 정보도 같은 방식으로 description에
  /// 묶어 저장한다). report_detail_screen.dart가 이 태그를 다시 읽어 "비용 부담"
  /// 항목에 실제 판정 결과를 보여준다(category_helpers.dart의
  /// applianceLiabilityFromDescription 참고).
  Future<Report> submitReport({
    required String description,
    List<File> photos = const [],
    String? availableTimes,
    void Function(int completed, int total)? onUploadProgress,
    Future<String?> Function(ApplianceQuestion question)? onApplianceQuestion,
  }) async {
    if (photos.isEmpty) {
      throw ApiException('사진을 최소 1장 첨부해야 합니다.');
    }
    final photoUrls = await uploadPhotos(photos, onProgress: onUploadProgress);

    final answers = <String, String>{};
    var analysis = await analyze(description: description, photoUrls: photoUrls);

    while (true) {
      final appliance = analysis['appliance'] as Map<String, dynamic>?;
      final questions = (appliance?['questions'] as List?) ?? const [];
      if (appliance == null || questions.isEmpty) break;

      if (onApplianceQuestion == null) {
        throw ApiException('가전 하자의 수리비 부담 주체를 확인하려면 추가 정보가 필요합니다.');
      }
      final question = ApplianceQuestion.fromJson(questions.first as Map<String, dynamic>);
      final answer = await onApplianceQuestion(question);
      if (answer == null) {
        throw ApiException('가전 정보 확인이 취소되어 신고를 접수하지 못했습니다.');
      }
      answers[question.id] = answer;
      analysis = await analyze(description: description, photoUrls: photoUrls, answers: answers);
    }

    final appliance = analysis['appliance'] as Map<String, dynamic>?;

    return createReport(
      description: _describeWithApplianceJudgement(description, appliance),
      photoUrls: photoUrls,
      category: analysis['category']?.toString(),
      severity: analysis['severity']?.toString(),
      // 가전 하자로 판정이 끝났으면(appliance.liability != null) 서버가 이미
      // recommended_path를 규칙 기반 값으로 덮어써서 돌려준다(LLM 1차 추측보다
      // 우선). 그대로 넘기면 된다.
      recommendedPath: analysis['recommended_path']?.toString(),
      selfFixGuide: analysis['self_fix_guide']?.toString(),
      applianceType: analysis['appliance_type']?.toString(),
      availableTimes: availableTimes,
    );
  }

  /// 가전 부담 주체 판정 결과를 description 끝에 "[가전 하자 판정]" 태그로
  /// 덧붙인다. 가전이 아니거나(appliance == null) 아직 판정이 끝나지 않았으면
  /// (liability == null) 원본 description을 그대로 돌려준다.
  String _describeWithApplianceJudgement(String description, Map<String, dynamic>? appliance) {
    final liability = appliance?['liability']?.toString();
    if (appliance == null || liability == null) return description;

    final notice = appliance['notice']?.toString();
    final warning = appliance['warning']?.toString();
    final lines = [
      description,
      '',
      '[가전 하자 판정] 비용 부담: ${_applianceLiabilityLabel(liability)}',
      if (notice != null && notice.isNotEmpty) notice,
      if (warning != null && warning.isNotEmpty) '⚠ $warning',
    ];
    return lines.join('\n');
  }

  String _applianceLiabilityLabel(String liability) {
    switch (liability) {
      case 'tenant':
        return '임차인 부담';
      case 'manufacturer_warranty':
        return '제조사 무상 수리 대상';
      case 'landlord':
        return '임대인 부담';
      case 'negotiable':
        return '협의 필요 (계약서 특약 확인)';
      default:
        return '확인 필요';
    }
  }

  /// 사진 한 장을 /api/uploads에 업로드하고 URL을 반환한다.
  Future<String> uploadPhoto(File photo) async {
    final response = await _api.uploadFile(photo);
    final data = response.data;
    if (data is Map && data['url'] != null) {
      return data['url'].toString();
    }
    throw ApiException('업로드 응답에 url이 없습니다.');
  }

  /// 여러 장을 병렬로 업로드하고, 입력 순서 그대로 URL 리스트를 반환한다.
  /// 하나라도 실패하면 어떤 파일이 실패했는지 알 수 있는 메시지와 함께
  /// [PhotoUploadException]을 던진다 (부분 성공 허용 안 함).
  Future<List<String>> uploadPhotos(
    List<File> photos, {
    void Function(int completed, int total)? onProgress,
  }) async {
    if (photos.isEmpty) return [];
    final total = photos.length;
    var completedCount = 0;

    return Future.wait(
      photos.asMap().entries.map((entry) async {
        final index = entry.key;
        final file = entry.value;
        try {
          final url = await uploadPhoto(file);
          completedCount++;
          onProgress?.call(completedCount, total);
          return url;
        } catch (e) {
          throw PhotoUploadException(
            '${index + 1}번째 사진(${file.path.split('/').last}) 업로드 실패: $e',
          );
        }
      }),
    );
  }

  /// 제조사 A/S 정보 조회 (recommended_path == manufacturer_as일 때 사용).
  Future<List<Map<String, dynamic>>> getManufacturerAs({required String category}) async {
    final response = await _api.get('/api/manufacturer-as', queryParameters: {'category': category});
    final data = response.data as Map<String, dynamic>;
    final list = (data['results'] as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 업체 매칭 (recommended_path == vendor_match일 때 사용).
  /// 백엔드는 reportId가 아니라 category로 활성 업체를 찾는다.
  Future<List<Vendor>> matchVendors({required String category}) async {
    final response = await _api.post('/api/vendors/match', data: {'category': category});
    final data = response.data as Map<String, dynamic>;
    final list = (data['vendors'] as List?) ?? [];
    return list.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// GET /api/vendors/requests?technicianId= — 업체가 아직 견적을 안 낸 신고 목록.
  /// technicianId는 AuthProvider.currentUser?.id(users.id) — 로그인만 하면 항상
  /// 있는 값이라, vendorId(vendors.id, technician signup/login에서만 오는 값)보다
  /// 이걸 쓰는 게 더 안전하다. 백엔드가 vendors.user_id로 알아서 업체를 찾아
  /// 응답에 vendor까지 함께 준다(vendorId로도 여전히 부를 수 있지만 안 씀).
  /// 새 업체 계정이면 결과가 비어 있을 수 있고, 그건 정상이다.
  Future<List<VendorRequest>> getVendorRequests({required String technicianId}) async {
    final response = await _api.get('/api/vendors/requests', queryParameters: {'technicianId': technicianId});
    final data = response.data as Map<String, dynamic>;
    final list = (data['requests'] as List?) ?? [];
    return list.map((e) => VendorRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}
