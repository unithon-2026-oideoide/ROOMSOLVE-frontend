import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "임대인 - 방문 일정 확정" 화면.
/// GET /api/repair/schedule?reportId=로 실제 확정 일정을 가져온다(requestId는
/// 곧 report id). 일정이 아직 없으면 디자인의 예시 값으로 대체한다.
class LandlordVisitScheduleScreen extends StatefulWidget {
  const LandlordVisitScheduleScreen({super.key, required this.requestId});

  final String requestId;

  @override
  State<LandlordVisitScheduleScreen> createState() => _LandlordVisitScheduleScreenState();
}

class _LandlordVisitScheduleScreenState extends State<LandlordVisitScheduleScreen> {
  Map<String, dynamic>? _schedule;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schedules = await RepairService.instance.getSchedules(reportId: widget.requestId);
      if (mounted && schedules.isNotEmpty) setState(() => _schedule = schedules.first);
    } on ApiException {
      // 일정이 아직 없으면 아래 예시 값으로 대체한다.
    } catch (_) {
      // 위와 동일.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = _schedule?['scheduled_at'] != null ? DateTime.tryParse(_schedule!['scheduled_at'].toString())?.toLocal() : null;
    final technician = _schedule?['technician'] as Map<String, dynamic>?;

    final dateLabel = scheduledAt != null
        ? '${scheduledAt.year}년 ${scheduledAt.month}월 ${scheduledAt.day}일'
        : '2025년 8월 14일 (목)';
    final timeLabel = scheduledAt != null
        ? '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}'
        : '오전 10:00 – 12:00';
    final technicianLabel = technician?['name']?.toString() ?? '든든배관';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
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
                                _Row('날짜', dateLabel),
                                _Row('시간', timeLabel),
                                _Row('담당 기사', technicianLabel),
                                const _Row('작업 내용', '화장실 누수 점검 및 수리'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => context.push('/landlord/requests/${widget.requestId}'),
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
            const AppBottomNav(current: AppBottomNavTab.home, homePath: '/landlord', reportsPath: '/landlord/requests'),
          ],
        ),
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
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          const SizedBox(width: 12),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.bodyRegular14(color: AppColors.gray8))),
        ],
      ),
    );
  }
}
