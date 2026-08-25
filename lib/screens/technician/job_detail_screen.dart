import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/technician_job.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "작업 상세 화면". 실제 배정 작업 API가 없어 [TechnicianJob] 목업을 그대로 사용한다.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final TechnicianJob job;

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
                    Row(
                      children: [
                        Expanded(child: Text('작업 상세', style: AppTextStyles.subtitleBold22(color: AppColors.black))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                          child: Text('배정됨', style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('요청 접수일: ${job.receivedAt}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    const SizedBox(height: 16),
                    _Card(
                      title: '작업 정보',
                      child: Column(
                        children: [
                          _Row('고장 유형', job.title),
                          _Row('위치', '${job.address} ${job.unit}'),
                          _Row('방문 요청 시간', job.visitTime),
                          _Row('연락처', job.contactPhone),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '증상 설명',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.symptomDescription, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          const SizedBox(height: 8),
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(color: const Color(0xFFE5E5EB), borderRadius: BorderRadius.circular(8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '작업 지시',
                      child: Text(job.instruction, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '진행 현황',
                      child: Column(
                        children: [
                          _ProgressRow(label: '작업 배정', color: AppColors.accentGreen, icon: Icons.check),
                          _ProgressRow(
                            label: '방문 일정 협의',
                            color: job.status == TechnicianJobStatus.scheduled ? AppColors.accentYellow : AppColors.accentGreen,
                            icon: job.status == TechnicianJobStatus.scheduled ? Icons.arrow_forward : Icons.check,
                          ),
                          _ProgressRow(
                            label: '현장 수리',
                            color: job.status == TechnicianJobStatus.inProgress ? AppColors.accentYellow : AppColors.gray3,
                            icon: job.status == TechnicianJobStatus.inProgress ? Icons.arrow_forward : Icons.circle_outlined,
                            iconColor: job.status == TechnicianJobStatus.inProgress ? AppColors.white : AppColors.gray8,
                          ),
                          _ProgressRow(
                            label: '완료 확인',
                            color: job.status == TechnicianJobStatus.completed ? AppColors.accentGreen : AppColors.gray3,
                            icon: job.status == TechnicianJobStatus.completed ? Icons.check : Icons.circle_outlined,
                            iconColor: job.status == TechnicianJobStatus.completed ? AppColors.white : AppColors.gray8,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('방문 가능 시간 제출 기능은 준비 중입니다.')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('방문 가능 시간 제출', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => context.push('/technician/jobs/${job.id}/complete', extra: job),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFBFBF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('수리 완료 처리', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                      ),
                    ),
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

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.color,
    required this.icon,
    this.iconColor = AppColors.white,
    this.isLast = false,
  });

  final String label;
  final Color color;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: iconColor),
          ),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
        ],
      ),
    );
  }
}
