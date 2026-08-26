import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/quote.dart';
import '../../services/landlord_service.dart';
import '../../services/quote_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/screen_header.dart';

/// "임대인 - 수리요청 상세" 레이아웃(요청 개요/AI 판단 요약/수리업체 제안 견적/
/// 타임라인/사진/요청 내용)에 "임대인 - 수리요청" 화면의 승인·거절 액션을
/// 합쳐서 하나의 상세 화면으로 구성한다.
class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _detail;
  List<Quote> _quotes = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  final _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await LandlordService.instance.getRequestDetail(widget.requestId);
      List<Quote> quotes = [];
      try {
        quotes = await QuoteService.instance.getQuotes(reportId: widget.requestId);
      } catch (_) {}

      // 만약 이미 선택된 견적이 있는데 status가 pending이라면 approved로 동기화
      if (quotes.any((q) => q.status == 'selected') && (result['status']?.toString().toLowerCase() == 'pending')) {
        result['status'] = 'approved';
        LandlordService.instance.approveRequest(id: widget.requestId, approve: true).catchError((_) {});
      }

      setState(() {
        _detail = result;
        _quotes = quotes;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '상세 정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectQuote(Quote quote) async {
    setState(() => _isSubmitting = true);
    try {
      await QuoteService.instance.updateQuoteStatus(quoteId: quote.id, status: 'selected');
      try {
        await LandlordService.instance.approveRequest(id: widget.requestId, approve: true);
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${quote.vendorName ?? '수리업체'} 견적을 선택하여 수리 승인했습니다.')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 수리 요청 거절. 승인은 여기로 오지 않는다 — 견적을 선택하면 서버가
  /// 신고를 approved로 올린다(quotes.controller.ts updateQuoteStatus).
  Future<void> _reject() async {
    setState(() => _isSubmitting = true);
    try {
      await LandlordService.instance.approveRequest(id: widget.requestId, approve: false);
      if (!mounted) return;
      context.pushReplacement('/landlord/requests/${widget.requestId}/rejected', extra: _rejectReasonController.text);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('처리 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// "임대인 - 수리요청 거절" 화면의 확인 다이얼로그.
  Future<void> _confirmReject() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('거절 처리 확인', style: AppTextStyles.bodySemiBold14(color: AppColors.black)),
        content: Text(
          '입력한 사유와 함께 거절 처리됩니다. 계속하시겠습니까?',
          style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBFBFBF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('취소', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(64, 36),
              backgroundColor: const Color(0xFFD93333),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('거절 확정', style: AppTextStyles.bodyRegular14(color: AppColors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _reject();
  }

  String get _effectiveStatus {
    final status = _detail?['status']?.toString().toLowerCase() ?? '';
    // 견적 목록 중 선택된(selected) 견적이 하나라도 있으면 무조건 'approved'(수리 대기)
    if (_quotes.any((q) => q.status == 'selected')) {
      return 'approved';
    }
    return status;
  }

  bool get _isPending {
    final status = _effectiveStatus;
    return status.isEmpty || status == 'pending';
  }

  String get _statusLabel => requestStatusLabel(_effectiveStatus);

  Color get _statusColor => requestStatusColor(_effectiveStatus);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(context)),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/landlord', reportsPath: '/landlord/requests'),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed)));
    }

    final d = _detail ?? const {};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScreenHeader(
            title: '수리 요청 상세',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(999)),
              child: Text(_statusLabel, style: AppTextStyles.bodySemiBold12(color: AppColors.white)),
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: '요청 개요',
            child: Column(
              children: [
                _KeyValueRow('요청 번호', d['id']?.toString() ?? widget.requestId),
                _KeyValueRow('신고 일시', formatDateTime(d['created_at']?.toString())),
                _KeyValueRow('세입자', (d['tenant'] as Map?)?['name']?.toString() ?? '-'),
                _KeyValueRow('세입자 연락처', (d['tenant'] as Map?)?['phone']?.toString() ?? '-'),
                _KeyValueRow('유형', categoryLabel(d['category']?.toString())),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: 'AI 판단 요약',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d['ai_summary']?.toString() ?? d['self_fix_guide']?.toString() ?? '분석 정보가 없습니다.',
                  style: AppTextStyles.bodyRegular14(color: AppColors.gray7),
                ),
                const SizedBox(height: 8),
                if (d['severity'] != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(text: '긴급도: ${severityLabel(d['severity']?.toString())}'),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  '※ 위 판단은 AI 분석 결과이며 현장 확인 후 변경될 수 있습니다.',
                  style: AppTextStyles.captionLight12(color: AppColors.gray6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            title: '수리업체 제안 견적',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_quotes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('제출된 업체 견적이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
                  )
                else
                  for (final quote in _quotes) ...[
                    _QuoteItem(
                      quote: quote,
                      canSelect: _isPending && quote.status != 'rejected' && quote.status != 'selected',
                      isSubmitting: _isSubmitting,
                      onSelect: () => _selectQuote(quote),
                    ),
                    if (quote != _quotes.last) const Divider(height: 16, color: Color(0xFFEEEEEE)),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if ((d['photo_urls'] as List?)?.isNotEmpty ?? false) ...[
            Text('신고 첨부 사진', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
            const SizedBox(height: 8),
            for (final url in (d['photo_urls'] as List)) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(url.toString(), height: 180, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
          Text('세입자 요청 내용', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
          const SizedBox(height: 8),
          _Card(
            title: '',
            child: Text(
              d['description']?.toString() ?? '설명 없음',
              style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
            ),
          ),
          if (_isPending) ...[
            const SizedBox(height: 24),
            Text('처리 결정', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
            const SizedBox(height: 8),
            // 승인 버튼은 없앴다. 바뀐 플로우에서 승인은 위 "수리업체 제안 견적"에서
            // 견적을 고르는 행위이고, 그때 서버가 신고를 approved로 올린다.
            // 버튼으로 따로 승인하면 업체가 안 정해진 채 approved가 되어, 그 뒤로는
            // 견적 선택 버튼이 잠겨 되돌릴 수 없었다.
            Text(
              '견적을 선택하면 해당 업체로 승인됩니다. 수리 자체가 필요 없다면 아래에서 거절하세요.',
              style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                boxShadow: AppColors.dropShadow,
              ),
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _confirmReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray5,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('수리 요청 거절', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8)],
              ),
              child: TextField(
                controller: _rejectReasonController,
                style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '거절 사유 입력',
                  hintStyle: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('거절 사유는 세입자에게 전달됩니다.', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.dropShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: AppTextStyles.subtitleBold18(color: AppColors.black)),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodySemiBold14(color: AppColors.gray8))),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.gray3, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppTextStyles.bodyRegular12(color: AppColors.gray8)),
    );
  }
}

class _QuoteItem extends StatelessWidget {
  const _QuoteItem({
    required this.quote,
    required this.canSelect,
    required this.isSubmitting,
    required this.onSelect,
  });

  final Quote quote;
  final bool canSelect;
  final bool isSubmitting;
  final VoidCallback onSelect;

  // 'recommended'는 견적 제출 직후의 초기 상태값일 뿐 추천이 아니다. 예전에는 이걸
  // "추천"으로 표시해서 제출된 모든 견적에 추천 배지가 붙었다. 실제 추천은 서버가
  // 가격·평점으로 매긴 1위(quote.isRecommended)이고 아래에서 따로 표시한다.
  String get _statusText {
    switch (quote.status.toLowerCase()) {
      case 'rejected':
        return '거절됨';
      case 'selected':
        return '선택됨';
      default:
        return '제출됨';
    }
  }

  Color get _statusBadgeColor {
    switch (quote.status.toLowerCase()) {
      case 'rejected':
        return AppColors.accentRed;
      case 'selected':
        return AppColors.brandMain;
      default:
        return AppColors.gray5;
    }
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: AppTextStyles.captionLight12(color: AppColors.white)),
    );
  }

  String _formatPrice(num? price) {
    if (price == null) return '-';
    final str = price.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) buffer.write(',');
    }
    return '${buffer.toString().split('').reversed.join()}원';
  }

  @override
  Widget build(BuildContext context) {
    final visitTimeStr = quote.proposedVisitAt != null
        ? formatDateTime(quote.proposedVisitAt!.toIso8601String())
        : '방문 시간 미지정';

    // 추천 견적만 테두리로 감싸 목록에서 바로 눈에 띄게 한다.
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: quote.isRecommended ? const EdgeInsets.all(12) : EdgeInsets.zero,
      decoration: quote.isRecommended
          ? BoxDecoration(
              color: AppColors.brandMain.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.brandMain),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      quote.vendorName ?? '수리업체',
                      style: AppTextStyles.bodySemiBold14(color: AppColors.black),
                    ),
                    if (quote.isRecommended) _badge('추천', AppColors.brandMain),
                    _badge(_statusText, _statusBadgeColor),
                    if (quote.isOutlier) _badge('과도한 견적', AppColors.accentRed),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatPrice(quote.price),
                      style: AppTextStyles.bodySemiBold14(color: AppColors.brandDark),
                    ),
                    if (quote.vendorRating != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 13, color: Color(0xFFF5A623)),
                      const SizedBox(width: 2),
                      Text(
                        quote.vendorRating!.toStringAsFixed(1),
                        style: AppTextStyles.bodyRegular12(color: AppColors.gray7),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '방문 가능 시간: $visitTimeStr',
                  style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                ),
                // 배지만 달면 "왜 이게 추천인지"를 되묻게 된다. 서버가 붙여 준 한 줄을
                // 그대로 보여 준다 (예: "최저가보다 5,000원(5%) 비싸지만 평점이 0.6점 높습니다").
                if (quote.recommendReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    quote.recommendReason!,
                    style: AppTextStyles.bodyRegular12(color: AppColors.brandDark),
                  ),
                ],
              ],
            ),
          ),
          if (canSelect)
            ElevatedButton(
              onPressed: isSubmitting ? null : onSelect,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(72, 34),
                backgroundColor: AppColors.brandMain,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text('업체 선택', style: AppTextStyles.bodyRegular12(color: AppColors.white)),
            ),
        ],
      ),
    );
  }
}
