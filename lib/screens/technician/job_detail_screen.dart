import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/category_helpers.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/technician_job.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/screen_header.dart';

/// "작업 상세 화면". technician_job_loader.dart를 통해 만들어진 TechnicianJob은
/// 정의상 이미 repair_schedule이 있는(=배정이 끝난) 일감이다. 이 업체가 이
/// 신고에 낼 견적은 새 일감 단계(new_request_detail_screen.dart, POST
/// /api/quotes만 호출)에서 이미 제출했고 임대인이 선택했기 때문에 여기서
/// 다시 견적/방문시간을 제출할 이유가 없다.
///
/// 예전에는 여기에도 "견적 제출" 폼이 있어 POST /api/quotes + POST
/// /api/repair/schedule을 다시 호출했는데, 이미 repair_schedule이 있는
/// report_id에 스케줄을 또 만드는 셈이라(repair_schedule.report_id에는 유니크
/// 제약도 없다) 같은 작업에 중복 일정이 쌓일 수 있었다. new_request_detail_screen.dart
/// 자체 주석이 "여기서 스케줄을 먼저 만들면 나중에 중복된다"고 설명하는
/// 규칙을 이 화면이 어기고 있었던 것 — 그 폼을 제거하고 "수리 완료 처리"로만
/// 이어지게 한다.
class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});

  final TechnicianJob job;

  @override
  Widget build(BuildContext context) {
    final location = [job.address, job.unit].where((s) => s.isNotEmpty).join(' ');
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
                    ScreenHeader(
                      title: '작업 상세',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: technicianJobStatusColor(job.statusLabel),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(job.statusLabel, style: AppTextStyles.bodySemiBold12(color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('요청 접수일: ${job.receivedAt}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    const SizedBox(height: 16),
                    _Card(
                      title: '작업 정보',
                      child: Column(
                        children: [
                          _Row('고장 유형', job.title),
                          _Row('위치', location.isNotEmpty ? location : '정보 없음'),
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
                          if (job.photoUrls.isNotEmpty)
                            for (final url in job.photoUrls)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url, height: 160, width: double.infinity, fit: BoxFit.cover),
                                ),
                              )
                          else if (job.photoUrl != null && job.photoUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(job.photoUrl!, height: 160, width: double.infinity, fit: BoxFit.cover),
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
                      child: OutlinedButton(
                        onPressed: job.status == TechnicianJobStatus.completed
                            ? null
                            : () => context.push('/technician/jobs/${job.id}/complete', extra: job),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFBFBF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          job.status == TechnicianJobStatus.completed ? '수리 완료됨' : '수리 완료 처리',
                          style: AppTextStyles.bodySemiBold14(color: AppColors.gray8),
                        ),
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
