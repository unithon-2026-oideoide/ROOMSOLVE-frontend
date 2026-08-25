import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../models/report.dart';
import '../models/vendor.dart';

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
  }) async {
    final response = await _api.post('/api/reports', data: {
      'description': description,
      'photoUrls': photos.map((f) => f.path).toList(),
    });
    return Report.fromJson(response.data as Map<String, dynamic>);
  }

  /// 사진 + 설명을 보내 AI 분석 결과(category/severity/recommended_path/self_fix_guide)를 받는다.
  Future<Report> analyzeReport({
    required String description,
    List<File> photos = const [],
  }) async {
    final formData = FormData.fromMap({
      'description': description,
      'photos': [
        for (final photo in photos) await MultipartFile.fromFile(photo.path, filename: photo.path.split('/').last),
      ],
    });
    final response = await _api.post('/api/reports/analyze', data: formData);
    return Report.fromJson(response.data as Map<String, dynamic>);
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
