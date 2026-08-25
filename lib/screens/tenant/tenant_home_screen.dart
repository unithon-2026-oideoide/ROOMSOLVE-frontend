import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../providers/auth_provider.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

class TenantHomeScreen extends StatefulWidget {
  const TenantHomeScreen({super.key});

  @override
  State<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends State<TenantHomeScreen> {
  List<Report>? _reports;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ReportService.instance.getReports();
      if (mounted) setState(() => _reports = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '요청 내역을 불러오지 못했습니다: $e');
    }
  }

  bool _isCompleted(Report r) => r.status == 'completed' || r.status == 'done' || r.status == '완료';
  bool _isWaiting(Report r) => r.status == null || r.status!.isEmpty || r.status == 'pending' || r.status == '대기';

  @override
  Widget build(BuildContext context) {
    final reports = _reports;
    final inProgress = reports?.where((r) => !_isCompleted(r) && !_isWaiting(r)).toList() ?? const [];
    final completed = reports?.where(_isCompleted).toList() ?? const [];
    final waiting = reports?.where(_isWaiting).toList() ?? const [];
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? user?.email.split('@').first ?? '사용자';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.titleBold30(color: AppColors.black),
                        children: [
                          const TextSpan(text: '안녕하세요, '),
                          TextSpan(text: userName, style: AppTextStyles.titleBold30(color: AppColors.brandMain)),
                          const TextSpan(text: '님'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '현재 수리 진행 상황을 확인하세요.',
                      style: AppTextStyles.subtitleRegular18(color: AppColors.gray6),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _StatColumn(label: '진행 중인 신고', count: inProgress.length)),
                          Expanded(child: _StatColumn(label: '완료된 신고', count: completed.length)),
                          Expanded(child: _StatColumn(label: '대기 중', count: waiting.length)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 39,
                      child: ElevatedButton(
                        onPressed: () => context.push('/tenant/reports/new'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          elevation: 0,
                        ),
                        child: Text('새 문제 신고하기', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('진행 중인 신고', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 16),
                    if (reports == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (inProgress.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('진행 중인 신고가 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
                      )
                    else
                      for (final r in inProgress) ...[
                        _ReportProgressCard(report: r),
                        const SizedBox(height: 16),
                      ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.accentYellow, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('긴급 안내', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                                const SizedBox(height: 4),
                                Text(
                                  '72시간 이상 응답이 없는 신고는 임대인에게 자동 알림이 발송됩니다.',
                                  style: AppTextStyles.bodyRegular12(color: AppColors.gray8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.home, homePath: '/tenant'),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodyRegular12(color: AppColors.gray7)),
        const SizedBox(height: 8),
        Text('$count건', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
      ],
    );
  }
}

class _ReportProgressCard extends StatelessWidget {
  const _ReportProgressCard({required this.report});
  final Report report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.dropShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.category ?? report.description ?? '분류 대기 중',
                  style: AppTextStyles.bodySemiBold16(color: AppColors.gray8),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  report.status ?? '처리 대기 중',
                  style: AppTextStyles.bodyRegular12(color: AppColors.gray8),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 25,
            child: ElevatedButton(
              onPressed: () => context.push('/tenant/reports/result', extra: report),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandLight,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 0,
              ),
              child: Text('자세히 보기', style: AppTextStyles.bodyRegular14(color: AppColors.gray1)),
            ),
          ),
        ],
      ),
    );
  }
}
