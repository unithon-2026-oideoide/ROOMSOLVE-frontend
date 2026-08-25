import 'dart:io';

import '../core/api_client.dart';
import '../models/report.dart';
import '../models/vendor.dart';

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

  /// 신고를 실제로 저장한다(POST /api/reports). 백엔드가 `landlord_id`를 필수로
  /// 요구하는데, 세입자와 임대인을 연결해 주는 테이블/조회 경로가 아직 백엔드에
  /// 없어(팀 README에도 명시된 알려진 gap) 프론트에서 landlord_id를 구할 방법이
  /// 없다. 그래서 이 메서드는 아직 어떤 화면에서도 호출하지 않는다 — 지금
  /// 신고 플로우는 [analyzeReport]까지만 쓰고, 저장 없이 결과를 보여준다.
  /// landlord_id를 얻는 방법이 정해지면 여기서 필수 파라미터로 받아 채워야 한다.
  Future<Report> createReport({
    required String description,
    required String landlordId,
    List<File> photos = const [],
    void Function(int completed, int total)? onUploadProgress,
  }) async {
    if (photos.isEmpty) {
      throw ApiException('사진을 최소 1장 첨부해야 합니다.');
    }
    final photoUrls = await uploadPhotos(photos, onProgress: onUploadProgress);
    final response = await _api.post('/api/reports', data: {
      'landlord_id': landlordId,
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
    });
    final data = response.data as Map<String, dynamic>;
    return Report.fromJson(data['report'] as Map<String, dynamic>);
  }

  /// 사진 + 설명을 보내 AI 분석 결과(category/severity/recommended_path/self_fix_guide)를 받는다.
  /// 사진은 먼저 /api/uploads로 한 장씩 업로드한 뒤, 받은 URL들을 photo_url(대표)/photo_urls(전체)로 전달한다.
  ///
  /// 이 API는 분류만 하고 DB에 저장하지 않는다(백엔드 주석 참고) — 응답에
  /// id/status/photo_urls가 없다. 화면에서 바로 쓸 수 있게, 방금 올린
  /// photoUrls와 함께 로컬에서 Report 객체를 만들어 반환한다. id가 비어 있으므로
  /// 이 Report를 갖고 하는 후속 API 호출(수리 진행 현황 등)은 데이터가 없을 뿐
  /// 에러로 죽지는 않는다.
  Future<Report> analyzeReport({
    required String description,
    List<File> photos = const [],
    void Function(int completed, int total)? onUploadProgress,
  }) async {
    if (photos.isEmpty) {
      throw ApiException('사진을 최소 1장 첨부해야 합니다.');
    }
    final photoUrls = await uploadPhotos(photos, onProgress: onUploadProgress);
    final response = await _api.post('/api/reports/analyze', data: {
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
    });
    final data = response.data as Map<String, dynamic>;
    return Report(
      id: '',
      description: description,
      photoUrl: photoUrls.first,
      photoUrls: photoUrls,
      category: data['category']?.toString(),
      severity: data['severity']?.toString(),
      recommendedPath: recommendedPathFromString(data['recommended_path']?.toString()),
      selfFixGuide: data['self_fix_guide']?.toString(),
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
}
