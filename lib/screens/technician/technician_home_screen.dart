import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/technician_job.dart';
import '../../providers/auth_provider.dart';
import '../../services/technician_job_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "수리기사 홈 화면". GET /api/repair/schedule(technicianId=)로 실제 배정
/// 일정을 가져온다. 배정된 일정이 없으면 [mockTechnicianJobs]로 대체한다.
class TechnicianHomeScreen extends StatefulWidget {
  const TechnicianHomeScreen({super.key});

  @override
  State<TechnicianHomeScreen> createState() => _TechnicianHomeScreenState();
}

class _TechnicianHomeScreenState extends State<TechnicianHomeScreen> {
  List<TechnicianJob>? _jobs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    final jobs = await loadTechnicianJobs(userId);
    if (mounted) setState(() => _jobs = jobs);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? user?.email.split('@').first ?? '기사';
    final jobs = _jobs;

    if (jobs == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const AppTopBar(),
              const Expanded(child: Center(child: CircularProgressIndicator())),
              const AppBottomNav(current: AppBottomNavTab.home, homePath: '/technician', reportsPath: '/technician/jobs'),
            ],
          ),
        ),
      );
    }

    final completed = jobs.where((j) => j.status == TechnicianJobStatus.completed).length;
    final inProgress = jobs.where((j) => j.status == TechnicianJobStatus.inProgress).length;
    final waiting = jobs.where((j) => j.status == TechnicianJobStatus.scheduled || j.status == TechnicianJobStatus.onHold).length;
    final schedule = jobs.where((j) => j.status != TechnicianJobStatus.completed).take(3).toList();

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
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('오늘의 작업', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                      TextButton(
                        onPressed: () => context.push('/settings'),
                        child: Text('설정', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('배정된 작업', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                              Text('${jobs.length}건', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: _CountTile(label: '완료', count: completed)),
                            const SizedBox(width: 8),
                            Expanded(child: _CountTile(label: '진행 중', count: inProgress)),
                            const SizedBox(width: 8),
                            Expanded(child: _CountTile(label: '대기', count: waiting)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('방문 일정', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                  const SizedBox(height: 12),
                  for (final job in schedule) ...[
                    _ScheduleCard(job: job, onTap: () => context.push('/technician/jobs/${job.id}', extra: job)),
                    const SizedBox(height: 12),
                  ],
                  GestureDetector(
                    onTap: () => context.push('/technician/jobs'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('배정 작업 목록 전체 보기', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          const Icon(Icons.arrow_forward, size: 18, color: AppColors.gray8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.home, homePath: '/technician', reportsPath: '/technician/jobs'),
          ],
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.dropShadow,
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
          const SizedBox(height: 4),
          Text('$count', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.job, required this.onTap});
  final TechnicianJob job;
  final VoidCallback onTap;

  Color get _priorityColor => job.priority == '긴급' ? AppColors.accentRed : AppColors.gray3;
  Color get _priorityText => job.priority == '긴급' ? AppColors.white : AppColors.black;

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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.visitTime, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                  if (job.address.isNotEmpty) Text(job.address, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                  Text('${job.title} — ${job.priority}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: _priorityColor, borderRadius: BorderRadius.circular(999)),
                        child: Text(job.priority, style: AppTextStyles.bodyRegular12(color: _priorityText)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.brandLight, borderRadius: BorderRadius.circular(999)),
                        child: Text(job.statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: const Color(0xFFE5E5EB), borderRadius: BorderRadius.circular(8)),
            ),
          ],
        ),
      ),
    );
  }
}
