import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/technician_job.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "배정 작업 목록 화면". 실제 배정 작업 API가 없어 [mockTechnicianJobs]를 사용한다.
class TechnicianJobListScreen extends StatefulWidget {
  const TechnicianJobListScreen({super.key});

  @override
  State<TechnicianJobListScreen> createState() => _TechnicianJobListScreenState();
}

class _TechnicianJobListScreenState extends State<TechnicianJobListScreen> {
  String _filter = '전체';

  static const _filters = ['전체', '방문 예정', '진행 중', '완료'];

  static const _groupOrder = [
    ('방문 예정', TechnicianJobStatus.scheduled),
    ('진행 중', TechnicianJobStatus.inProgress),
    ('보류', TechnicianJobStatus.onHold),
    ('완료', TechnicianJobStatus.completed),
  ];

  @override
  Widget build(BuildContext context) {
    final jobs = mockTechnicianJobs.where((j) => _filter == '전체' || j.statusLabel == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  Text('배정 작업 목록', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: AppColors.dropShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('작업 상태', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                        const Icon(Icons.expand_more, size: 16, color: AppColors.gray8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in _filters)
                        GestureDetector(
                          onTap: () => setState(() => _filter = f),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _filter == f ? AppColors.brandDark : AppColors.brandLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(f, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final group in _groupOrder)
                    if (jobs.any((j) => j.status == group.$2)) ...[
                      Text(group.$1, style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                      const SizedBox(height: 8),
                      for (final job in jobs.where((j) => j.status == group.$2)) ...[
                        _JobRow(job: job, onTap: () => context.push('/technician/jobs/${job.id}', extra: job)),
                        const SizedBox(height: 8),
                      ],
                      const SizedBox(height: 8),
                    ],
                  if (jobs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('해당 상태의 작업이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6))),
                    ),
                ],
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/technician', reportsPath: '/technician/jobs'),
          ],
        ),
      ),
    );
  }
}

class _JobRow extends StatelessWidget {
  const _JobRow({required this.job, required this.onTap});
  final TechnicianJob job;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(job.title, style: AppTextStyles.bodyRegular16(color: AppColors.gray8)),
                      const SizedBox(height: 4),
                      Text('${job.unit} · ${job.tenantName}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                  child: Text(job.statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(job.address, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(job.visitTime, style: AppTextStyles.bodyRegular12(color: AppColors.gray6))),
                Expanded(child: Text(job.priority, style: AppTextStyles.bodyRegular12(color: AppColors.gray6))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
