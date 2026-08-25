import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/vendor_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/quote_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// "새 일감 상세 화면". 견적(가격 + 방문 가능 시간)을 POST /api/quotes로 낸다.
/// job_detail_screen.dart와 달리 POST /api/repair/schedule은 호출하지 않는다 —
/// 여기서는 아직 이 업체로 확정된 게 아니라서다. 임대인이 이 견적을
/// selected로 바꾸는 순간, 백엔드(quotes.controller.ts updateQuoteStatus)가
/// repair_schedule을 알아서 만든다. 여기서 먼저 만들면 나중에 중복된다.
class NewRequestDetailScreen extends StatefulWidget {
  const NewRequestDetailScreen({super.key, required this.request});

  final VendorRequest request;

  @override
  State<NewRequestDetailScreen> createState() => _NewRequestDetailScreenState();
}

class _NewRequestDetailScreenState extends State<NewRequestDetailScreen> {
  final _priceController = TextEditingController();
  DateTime? _proposedVisitTime;
  bool _isSubmitting = false;
  // 목록 화면에서 넘어온 alreadyQuoted가 true면 폼을 애초에 숨긴다 — DB에
  // 같은 (report, vendor) 쌍의 중복 견적을 막는 제약이 없어서, 화면에서
  // 막지 않으면 재제출로 quotes에 중복 행이 쌓인다.
  late bool _submitted = widget.request.alreadyQuoted;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickProposedVisitTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _proposedVisitTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _proposedVisitTime != null
          ? TimeOfDay(hour: _proposedVisitTime!.hour, minute: _proposedVisitTime!.minute)
          : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _proposedVisitTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submitQuote() async {
    final vendorId = context.read<AuthProvider>().currentUser?.vendorId;
    if (vendorId == null || vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업체 정보를 확인할 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final priceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '').trim();
    if (priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('견적 금액을 입력해주세요.')));
      return;
    }
    if (_proposedVisitTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('방문 가능 시간을 선택해주세요.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await QuoteService.instance.createQuote(
        reportId: widget.request.id,
        vendorId: vendorId,
        price: num.parse(priceText),
        proposedVisitAt: _proposedVisitTime,
      );
      if (mounted) {
        setState(() => _submitted = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('견적을 제출했습니다. 임대인이 선택하면 방문 일정이 자동으로 잡힙니다.')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제출 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('새 일감 상세', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 4),
                    Text('접수일: ${formatDateTime(request.createdAt?.toIso8601String())}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    const SizedBox(height: 16),
                    _Card(
                      title: '신고 정보',
                      child: Column(
                        children: [
                          _Row('고장 유형', categoryLabel(request.category)),
                          _Row('긴급도', severityLabel(request.severity)),
                          _Row('세입자 가능 시간', (request.availableTimes ?? '').isNotEmpty ? request.availableTimes! : '전달받은 정보 없음'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '증상 설명',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (request.description ?? '').isNotEmpty ? request.description! : '증상 설명이 없습니다.',
                            style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                          ),
                          const SizedBox(height: 8),
                          if (request.photoUrls.isNotEmpty || request.photoUrl != null)
                            for (final url in request.photoUrls.isNotEmpty ? request.photoUrls : [request.photoUrl!])
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover),
                                ),
                              )
                          else
                            Container(
                              height: 160,
                              width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFE5E5EB), borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Text('첨부 사진 없음', style: TextStyle(color: AppColors.gray6))),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '견적 제출 (수리 금액 + 방문 가능 시간)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_submitted)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '견적 제출 완료. 임대인이 선택하면 배정 작업 목록에서 확인할 수 있습니다.',
                                style: AppTextStyles.bodyRegular14(color: AppColors.brandMain),
                              ),
                            )
                          else ...[
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFAFAFA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.gray3),
                                    ),
                                    child: TextField(
                                      controller: _priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(border: InputBorder.none, hintText: '금액(원) 입력', isDense: true),
                                      style: AppTextStyles.bodyRegular14(color: AppColors.black),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 3,
                                  child: OutlinedButton.icon(
                                    onPressed: _pickProposedVisitTime,
                                    icon: const Icon(Icons.calendar_today, size: 14, color: AppColors.brandMain),
                                    label: Text(
                                      _proposedVisitTime != null
                                          ? '${_proposedVisitTime!.month}/${_proposedVisitTime!.day} ${_proposedVisitTime!.hour}:${_proposedVisitTime!.minute.toString().padLeft(2, '0')}'
                                          : '방문 시간 선택',
                                      style: AppTextStyles.bodyRegular12(color: AppColors.brandMain),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.brandMain),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submitQuote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.brandLight,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                    : Text('견적 제출', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_submitted) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => context.pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBFBFBF)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text('목록으로', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
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
          Text(title, style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.bodyRegular14(color: AppColors.gray8))),
        ],
      ),
    );
  }
}
