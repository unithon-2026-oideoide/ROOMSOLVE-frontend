import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// "신고 내역 화면"
class ReportListScreen extends StatefulWidget {
  const ReportListScreen({super.key});

  @override
  State<ReportListScreen> createState() => _ReportListScreenState();
}

class _ReportListScreenState extends State<ReportListScreen> {
  List<Report>? _reports;
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = '전체';

  // reports.status는 실제로 pending/approved/rejected 세 값만 나온다
  // (landlord.controller.ts approveRequest 확인함). Report.statusLabel과 맞춘다.
  static const _filters = ['전체', '접수 완료', '수리 대기', '완료', '거절됨'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await ReportService.instance.getReports();
      setState(() {
        _reports = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '요청 내역을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String label) {
    switch (label) {
      case '접수 완료':
        return AppColors.accentGreen;
      case '수리 대기':
      case '승인됨':
        return AppColors.brandMain;
      case '거절됨':
        return AppColors.accentRed;
      case '완료':
        return AppColors.gray5;
      default:
        return AppColors.brandMain;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _reports ?? const [];
    final filtered = all.where((r) => _filter == '전체' || r.statusLabel == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                // RefreshIndicator의 직접 자식은 항상 같은 Scrollable(ListView)이어야
                // 한다. 로딩/에러 상태에서 다른 위젯으로 통째로 바꿔치기하면
                // Flutter 렌더링 엔진이 '!semantics.parentDataDirty' assertion으로
                // 죽는 경우가 있어, 상태별 콘텐츠도 전부 ListView 안의 아이템으로 둔다.
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: _isLoading
                      ? const [
                          SizedBox(height: 80),
                          Center(child: CircularProgressIndicator()),
                        ]
                      : _errorMessage != null
                          ? [
                              const SizedBox(height: 80),
                              Center(child: Text(_errorMessage!, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed))),
                            ]
                          : [
                              Text('신고 내역', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.gray1,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: AppColors.dropShadow,
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: _filter,
                                    icon: const Icon(Icons.expand_more, size: 16, color: AppColors.gray8),
                                    style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                                    items: [for (final f in _filters) DropdownMenuItem(value: f, child: Text(f))],
                                    onChanged: (v) => setState(() => _filter = v ?? '전체'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (filtered.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text('등록된 신고가 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
                                  ),
                                )
                              else
                                for (final r in filtered) ...[
                                  _ReportRow(
                                    report: r,
                                    statusLabel: r.statusLabel,
                                    statusColor: _statusColor(r.statusLabel),
                                    onTap: () => context.push('/tenant/reports/${r.id}', extra: r),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                            ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/tenant', reportsPath: '/tenant/reports'),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.statusLabel, required this.statusColor, required this.onTap});

  final Report report;
  final String statusLabel;
  final Color statusColor;
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
                Expanded(
                  child: Text(
                    formatReportTitle(report.category, report.description),
                    style: AppTextStyles.subtitleSemiBold16(color: AppColors.gray8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(999)),
                  child: Text(statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (report.createdAt != null)
              Text(
                '접수 ${report.createdAt!.year}.${report.createdAt!.month.toString().padLeft(2, '0')}.${report.createdAt!.day.toString().padLeft(2, '0')}',
                style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
              ),
            const SizedBox(height: 8),
            Text(report.statusLabel, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          ],
        ),
      ),
    );
  }
}
