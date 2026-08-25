import '../core/api_client.dart';
import '../models/quote.dart';

class QuoteService {
  QuoteService._();
  static final QuoteService instance = QuoteService._();

  final _api = ApiClient.instance;

  Future<List<Quote>> getQuotes({required String reportId}) async {
    final response = await _api.get('/api/quotes', queryParameters: {'reportId': reportId});
    final list = (response.data as List?) ?? [];
    return list.map((e) => Quote.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Quote> createQuote({
    required String reportId,
    required String vendorId,
    required num price,
  }) async {
    final response = await _api.post('/api/quotes', data: {
      'reportId': reportId,
      'vendorId': vendorId,
      'price': price,
    });
    return Quote.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Quote> updateQuoteStatus({
    required String quoteId,
    required String status,
  }) async {
    final response = await _api.patch('/api/quotes/$quoteId/status', data: {'status': status});
    return Quote.fromJson(response.data as Map<String, dynamic>);
  }
}
