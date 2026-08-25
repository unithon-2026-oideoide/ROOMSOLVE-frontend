import '../core/api_client.dart';
import '../models/quote.dart';

class QuoteService {
  QuoteService._();
  static final QuoteService instance = QuoteService._();

  final _api = ApiClient.instance;

  // GET /api/quotes는 배열이 아니라 {quotes, median, replacementAdvice} 객체를
  // 준다(quotes.controller.ts listQuotes). response.data를 바로 List로 캐스팅하면
  // 항상 캐스트 실패로 죽는다.
  Future<List<Quote>> getQuotes({required String reportId}) async {
    final response = await _api.get('/api/quotes', queryParameters: {'reportId': reportId});
    final data = response.data as Map<String, dynamic>;
    final list = (data['quotes'] as List?) ?? [];
    return list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Quote> createQuote({
    required String reportId,
    required String vendorId,
    required num price,
  }) async {
    // 백엔드는 report_id/vendor_id(snake_case)를 요구한다(quotes.controller.ts
    // createQuote) — camelCase로 보내면 항상 400 "report_id, vendor_id는
    // 필수입니다"로 거부된다.
    final response = await _api.post('/api/quotes', data: {
      'report_id': reportId,
      'vendor_id': vendorId,
      'price': price,
    });
    final data = response.data as Map<String, dynamic>;
    return Quote.fromJson(data['quote'] as Map<String, dynamic>);
  }

  Future<Quote> updateQuoteStatus({
    required String quoteId,
    required String status,
  }) async {
    final response = await _api.patch('/api/quotes/$quoteId/status', data: {'status': status});
    final data = response.data as Map<String, dynamic>;
    return Quote.fromJson(data['quote'] as Map<String, dynamic>);
  }
}
