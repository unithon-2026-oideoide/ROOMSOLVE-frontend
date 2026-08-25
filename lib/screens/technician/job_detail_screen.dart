import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../models/technician_job.dart';
import '../../providers/auth_provider.dart';
import '../../services/repair_service.dart';
import '../../services/technician_job_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "작업 상세 화면". job이 실제 배정 데이터(스케줄+리포트 조합)면 "방문 가능
/// 시간 제출"이 POST /api/repair/schedule을 실제로 호출한다. 위치/연락처/작업
/// 지시는 백엔드에 대응 필드가 없어 정보 없음으로 표시될 수 있다.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({super.key, required this.job});

  final TechnicianJob job;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isSubmittingSchedule = false;
  // widget.job은 라우트로 넘어온 시점의 스냅샷이라 화면 안에서 갱신할 수 없다.
  // 방문 시간 제출 성공 후 실제 상태를 다시 반영하려면 이 로컬 상태를 바꿔야 한다
  // (아래 _refreshJob 참고) — 그렇지 않으면 제출에 성공해도 상단 뱃지/진행
  // 현황이 제출 전 상태로 화면이 열려있는 내내 그대로 남는다.
  late TechnicianJob _job;

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  Future<void> _submitVisitTime() async {
    final technicianId = context.read<AuthProvider>().currentUser?.id;
    if (technicianId == null || technicianId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사용자 정보를 확인할 수 없습니다. 다시 로그인해주세요.')),
      );
      return;
    }

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;

    final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() => _isSubmittingSchedule = true);
    try {
      await RepairService.instance.createSchedule(
        reportId: _job.id,
        technicianId: technicianId,
        scheduledAt: scheduledAt,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('방문 가능 시간을 제출했습니다.')),
        );
      }
      await _refreshJob(technicianId);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('제출 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isSubmittingSchedule = false);
    }
  }

  /// 배정 목록을 다시 불러와 이 작업의 최신 상태로 _job을 교체한다. 실패해도
  /// 방금 제출 자체는 이미 성공했으니 화면은 기존 _job으로 그대로 둔다.
  Future<void> _refreshJob(String technicianId) async {
    try {
      final jobs = await loadTechnicianJobs(technicianId);
      final updated = jobs.where((j) => j.id == _job.id);
      if (mounted && updated.isNotEmpty) setState(() => _job = updated.first);
    } catch (_) {
      // 갱신 실패는 무시 — 위 주석 참고.
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final location = [job.address, job.unit].where((s) => s.isNotEmpty).join(' ');
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
                          child: Text(job.statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
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
                      child: ElevatedButton(
                        onPressed: _isSubmittingSchedule ? null : _submitVisitTime,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isSubmittingSchedule
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text('방문 가능 시간 제출', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
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
