import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_storage.dart';

/// API 호출 실패 시 화면에 그대로 보여줄 수 있는 정규화된 예외.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// 공통 API 클라이언트. baseUrl은 .env의 API_BASE_URL에서 읽는다.
/// 나중에 백엔드 주소가 바뀌면 .env만 수정하면 된다.
class ApiClient {
  ApiClient._internal() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000';
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.instance.readAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _run(() => _dio.get(path, queryParameters: queryParameters));
  }

  Future<Response<dynamic>> post(String path, {Object? data}) {
    return _run(() => _dio.post(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {Object? data}) {
    return _run(() => _dio.patch(path, data: data));
  }

  /// 파일 하나를 /api/uploads로 업로드한다. 필드명은 file 고정.
  Future<Response<dynamic>> uploadFile(File file) {
    return _run(() async {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      return _dio.post('/api/uploads', data: formData);
    });
  }

  Future<Response<dynamic>> _run(Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException(_messageFrom(e), statusCode: e.response?.statusCode);
    } catch (e) {
      throw ApiException('알 수 없는 오류가 발생했습니다: $e');
    }
  }

  String _messageFrom(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없습니다. 네트워크 상태를 확인해주세요.';
      default:
        return '요청 처리 중 오류가 발생했습니다 (${e.response?.statusCode ?? '알 수 없음'}).';
    }
  }
}
