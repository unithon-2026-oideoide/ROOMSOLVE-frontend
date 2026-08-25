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
    final list = (response.data as List?) ?? [];
    return list.map((e) => Report.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Report> getReport(String id) async {
    final response = await _api.get('/api/reports/$id');
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Report> createReport({
    required String description,
    List<File> photos = const [],
    void Function(int completed, int total)? onUploadProgress,
  }) async {
    if (photos.isEmpty) {
      throw ApiException('사진을 최소 1장 첨부해야 합니다.');
    }
    final photoUrls = await uploadPhotos(photos, onProgress: onUploadProgress);
    final response = await _api.post('/api/reports', data: {
      'description': description,
      'photo_url': photoUrls.first,
      'photo_urls': photoUrls,
    });
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  /// 사진 + 설명을 보내 AI 분석 결과(category/severity/recommended_path/self_fix_guide)를 받는다.
  /// 사진은 먼저 /api/uploads로 한 장씩 업로드한 뒤, 받은 URL들을 photo_url(대표)/photo_urls(전체)로 전달한다.
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
    return Report.fromJson(response.data as Map<String, dynamic>);
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
    final list = (response.data as List?) ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  /// 업체 매칭 (recommended_path == vendor_match일 때 사용).
  Future<List<Vendor>> matchVendors({required String reportId}) async {
    final response = await _api.post('/api/vendors/match', data: {'reportId': reportId});
    final list = (response.data as List?) ?? [];
    return list.map((e) => Vendor.fromJson(e as Map<String, dynamic>)).toList();
  }
}
