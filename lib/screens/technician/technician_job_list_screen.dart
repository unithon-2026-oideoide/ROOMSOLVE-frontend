import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/technician_job.dart';
import '../../providers/auth_provider.dart';
import '../../services/technician_job_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// "배정 작업 목록 화면". GET /api/repair/schedule(technicianId=)로 실제 배정
/// 일정을 가져온다. 배정된 일정이 없으면 빈 상태 안내를 보여준다.
class TechnicianJobListScreen extends StatefulWidget {
  const TechnicianJobListScreen({super.key});

  @override
  State<TechnicianJobListScreen> createState() => _TechnicianJobListScreenState();
}

class _TechnicianJobListScreenState extends State<TechnicianJobListScreen> {
  String _filter = '전체';
  List<TechnicianJob>? _allJobs;
  String? _errorMessage;

  static const _filters = ['전체', '방문 예정', '진행 중', '완료'];

  static const _groupOrder = [
    ('방문 예정', TechnicianJobStatus.scheduled),
    ('진행 중', TechnicianJobStatus.inProgress),
    ('보류', TechnicianJobStatus.onHold),
    ('완료', TechnicianJobStatus.completed),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    try {
      final jobs = await loadTechnicianJobs(userId);
      if (mounted) setState(() { _allJobs = jobs; _errorMessage = null; });
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '배정 작업을 불러오지 못했습니다: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final allJobs = _allJobs;
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyRegular14(color: AppColors.accentRed),
                    ),
                  ),
                ),
              ),
              const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/technician', reportsPath: '/technician/jobs'),
            ],
          ),
        ),
      );
    }
    if (allJobs == null) {
      return Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Expanded(child: Center(child: CircularProgressIndicator())),
              const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/technician', reportsPath: '/technician/jobs'),
            ],
          ),
        ),
      );
    }
    final jobs = allJobs.where((j) => _filter == '전체' || j.statusLabel == _filter).toList();

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
                        child: Center(
                          child: Text(
                            _filter == '전체' ? '배정된 수리 작업이 없습니다.' : '$_filter 상태의 작업이 없습니다.',
                            style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
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
                      if (job.unit.isNotEmpty || job.tenantName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [job.unit, job.tenantName].where((s) => s.isNotEmpty).join(' · '),
                          style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                        ),
                      ],
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
            if (job.address.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(job.address, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
            ],
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
