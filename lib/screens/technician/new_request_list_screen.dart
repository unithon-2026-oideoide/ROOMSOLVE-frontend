import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/vendor_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// "새 일감 목록 화면". GET /api/vendors/requests(technicianId=)로, 업체의 전문
/// 분야에 해당하는 신고를 가져온다. 배정 작업 목록(이미 repair_schedule이
/// 있는 것)과는 별개다 — 여기서 견적을 내야 그중 하나가 선택됐을 때 비로소
/// 배정 작업이 된다. alreadyQuoted가 true인 항목은 이미 견적을 낸 신고라
/// 목록에서 구분해서 보여준다(재제출을 막는 제약이 DB에 없어서, 화면에서
/// 막지 않으면 quotes에 중복 행이 쌓인다).
class NewRequestListScreen extends StatefulWidget {
  const NewRequestListScreen({super.key});

  @override
  State<NewRequestListScreen> createState() => _NewRequestListScreenState();
}

class _NewRequestListScreenState extends State<NewRequestListScreen> {
  List<VendorRequest>? _requests;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final technicianId = context.read<AuthProvider>().currentUser?.id;
    if (technicianId == null || technicianId.isEmpty) {
      setState(() => _errorMessage = '사용자 정보를 확인할 수 없습니다. 다시 로그인해주세요.');
      return;
    }
    try {
      final requests = await ReportService.instance.getVendorRequests(technicianId: technicianId);
      if (mounted) setState(() { _requests = requests; _errorMessage = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '새 일감을 불러오지 못했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = _requests;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    Text('새 일감', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 4),
                    Text(
                      '내 전문 분야에 해당하고 아직 견적을 내지 않은 신고입니다.',
                      style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed)),
                        ),
                      )
                    else if (requests == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (requests.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text('지금은 새로 들어온 일감이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
                        ),
                      )
                    else
                      for (final request in requests) ...[
                        _RequestRow(
                          request: request,
                          onTap: () => context.push('/technician/requests/${request.id}', extra: request),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/technician', reportsPath: '/technician/jobs'),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onTap});
  final VendorRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            Row(
              children: [
                Expanded(child: Text(request.title, style: AppTextStyles.bodyRegular16(color: AppColors.gray8))),
                if (request.alreadyQuoted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: AppColors.gray5, borderRadius: BorderRadius.circular(999)),
                    child: Text('견적 제출됨', style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                  child: Text(severityLabel(request.severity), style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                ),
              ],
            ),
            if ((request.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(request.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
            ],
            if ((request.availableTimes ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('세입자 가능 시간: ${request.availableTimes}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
            ],
          ],
        ),
      ),
    );
  }
}
