import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "임대인 - 수리요청 상세" 레이아웃(요청 개요/AI 판단 요약/비용·업체 정보/
/// 타임라인/사진/요청 내용)에 "임대인 - 수리요청" 화면의 승인·거절 액션을
/// 합쳐서 하나의 상세 화면으로 구성한다. 요청이 이미 승인/거절된 경우
/// 처리 결정 섹션은 숨긴다.
class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Map<String, dynamic>? _detail;
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
      setState(() {
        _detail = result;
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

  Future<void> _respond(bool approve) async {
    setState(() => _isSubmitting = true);
    try {
      await LandlordService.instance.approveRequest(id: widget.requestId, approve: approve);
      if (!mounted) return;
      if (approve) {
        context.pop();
      } else {
        context.pushReplacement('/landlord/requests/${widget.requestId}/rejected', extra: _rejectReasonController.text);
      }
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
              backgroundColor: const Color(0xFFD93333),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text('거절 확정', style: AppTextStyles.bodyRegular14(color: AppColors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _respond(false);
  }

  bool get _isPending {
    final status = _detail?['status']?.toString().toLowerCase() ?? '';
    return status.isEmpty || status == 'pending' || status.contains('대기');
  }

  String get _statusLabel => _detail?['status']?.toString() ?? '승인 대기';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
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
          Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back, color: AppColors.black),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text('수리 요청 상세', style: AppTextStyles.subtitleBold22(color: AppColors.black))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: AppColors.accentGreen, borderRadius: BorderRadius.circular(999)),
                child: Text(_statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Card(
            title: '요청 개요',
            child: Column(
              children: [
                _KeyValueRow('요청 번호', d['id']?.toString() ?? widget.requestId),
                _KeyValueRow('신고 일시', d['created_at']?.toString() ?? '-'),
                _KeyValueRow('세입자', (d['tenant'] as Map?)?['name']?.toString() ?? '-'),
                _KeyValueRow('세입자 연락처', (d['tenant'] as Map?)?['phone']?.toString() ?? '-'),
                _KeyValueRow('유형', d['category']?.toString() ?? '-'),
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
                  d['self_fix_guide']?.toString() ?? d['description']?.toString() ?? '분석 정보가 없습니다.',
                  style: AppTextStyles.bodyRegular14(color: AppColors.gray7),
                ),
                const SizedBox(height: 8),
                if (d['severity'] != null)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(text: '긴급도: ${d['severity']}'),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : () => _respond(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandLight,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 0,
                      ),
                      child: Text('승인', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmReject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gray5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 0,
                      ),
                      child: Text('거절', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                    ),
                  ),
                ),
              ],
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
