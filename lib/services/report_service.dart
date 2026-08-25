import 'dart:io';

import '../core/api_client.dart';
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
    String? aiSummary,
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
      'ai_summary': ?aiSummary,
      'appliance_type': ?applianceType,
      'available_times': ?availableTimes,
    });
    final data = response.data as Map<String, dynamic>;
    return Report.fromJson(data['report'] as Map<String, dynamic>);
  }

  /// 세입자의 신고 접수 플로우 전체(사진 업로드 → AI 분석 → DB 저장)를 한 번에
  /// 처리한다. report_additional_info_screen이 "다음 단계로"에서 호출하는
  /// 유일한 진입점이다.
  ///
  /// landlord_id는 보내지 않는다 — createReport가 서버 쪽 linked_landlord_id로
  /// 채우게 둔다. 아직 임대인과 연결돼 있지 않으면 createReport 단계에서
  /// ApiException이 던져지는데, 메시지에 "설정에서 임대인 초대 코드를 먼저
  /// 입력"하라는 안내가 포함되어 있어 화면에 그대로 보여주면 된다.
  ///
  /// [availableTimes]는 세입자가 집에 있는 시간대(예: "평일 오후, 주말 오전").
  /// 업체가 방문 시간을 제안할 때 참고하는 값이라 AI 분석에는 넘기지 않고
  /// 저장만 한다.
  Future<Report> submitReport({
    required String description,
    List<File> photos = const [],
    String? availableTimes,
    void Function(int completed, int total)? onUploadProgress,
  }) async {
    if (photos.isEmpty) {
      throw ApiException('사진을 최소 1장 첨부해야 합니다.');
    }
    final photoUrls = await uploadPhotos(photos, onProgress: onUploadProgress);

    final analyzeResponse = await _api.post('/api/reports/analyze', data: {
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
    });
    final analysis = analyzeResponse.data as Map<String, dynamic>;

    return createReport(
      description: description,
      photoUrls: photoUrls,
      category: analysis['category']?.toString(),
      severity: analysis['severity']?.toString(),
      recommendedPath: analysis['recommended_path']?.toString(),
      selfFixGuide: analysis['self_fix_guide']?.toString(),
      aiSummary: analysis['ai_summary']?.toString(),
      applianceType: analysis['appliance_type']?.toString(),
      availableTimes: availableTimes,
    );
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
