import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/report.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "세입자 - 방문 일정 확정" 화면.
/// 백엔드에 방문 일정 전용 API가 아직 없어, 확정 일정 상세(날짜/시간/업체/작업
/// 내용)는 디자인의 예시 값을 그대로 표시한다. 방문 일정 API가 추가되면
/// report에서 해당 값을 채우도록 교체해야 한다.
class ReportVisitScheduleScreen extends StatelessWidget {
  const ReportVisitScheduleScreen({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('방문 일정이 확정되었습니다', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 8),
                    Text(
                      '수리기사가 아래 일정에 방문할 예정입니다. 방문 전날 알림을 보내드립니다.',
                      style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                    ),
                    const SizedBox(height: 24),
                    Container(
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
                          Text('확정된 방문 일정', style: AppTextStyles.subtitleSemiBold16(color: AppColors.gray8)),
                          const SizedBox(height: 12),
                          _InfoRow(label: '날짜', value: '2025년 8월 14일 (목)'),
                          _InfoRow(label: '시간', value: '오전 10:00 – 12:00'),
                          _InfoRow(label: '수리업체', value: '든든배관'),
                          _InfoRow(label: '작업 내용', value: report.category ?? '화장실 누수 점검 및 수리'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
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
                          Text('방문 전 확인 사항', style: AppTextStyles.subtitleSemiBold16(color: AppColors.gray8)),
                          const SizedBox(height: 8),
                          Text('• 방문 시간에 자리를 지켜 주세요.', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          Text(
                            '• 수리 부위 주변을 미리 정리해 두시면 작업이 빠르게 진행됩니다.',
                            style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                          ),
                          Text(
                            '• 일정 변경이 필요하면 수리 진행 현황 화면에서 요청할 수 있습니다.',
                            style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => context.push('/tenant/reports/${report.id}/progress', extra: report),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('수리 진행 현황 보기', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
            ),
          ),
        ],
      ),
    );
  }
}
