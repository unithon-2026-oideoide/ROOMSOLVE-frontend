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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final schedules = await RepairService.instance.getSchedules(reportId: widget.requestId);
      // schedules가 빈 배열인 건 조회 성공 + "아직 일정이 없음"이라 정상 케이스다.
      // 이 경우에만 아래 예시 값으로 대체한다. 조회 자체가 실패한 경우(아래 catch)를
      // 조용히 삼키고 예시 값을 "확정된 일정"인 것처럼 보여주면 안 된다.
      if (mounted && schedules.isNotEmpty) setState(() => _schedule = schedules.first);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = '일정 정보를 불러오지 못했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = _schedule?['scheduled_at'] != null ? DateTime.tryParse(_schedule!['scheduled_at'].toString())?.toLocal() : null;
    final technician = _schedule?['technician'] as Map<String, dynamic>?;
    // 조회는 성공했지만 아직 일정이 없는 정상 케이스에도 디자인 예시 값을
    // "확정된 일정"처럼 보여주면 안 된다 — report_visit_schedule_screen.dart와
    // 동일한 이유.
    final hasSchedule = scheduledAt != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyRegular14(color: AppColors.accentRed),
                            ),
                          ),
                        )
                      : !hasSchedule
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '아직 방문 일정이 확정되지 않았습니다',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.subtitleBold22(color: AppColors.black),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '견적을 선택하면 업체가 제안한 시간으로 방문 일정이 자동으로 잡힙니다.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
                                    ),
                                  ],
                                ),
                              ),
                            )
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
                                _Row('날짜', '${scheduledAt.year}년 ${scheduledAt.month}월 ${scheduledAt.day}일'),
                                _Row(
                                  '시간',
                                  '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                                ),
                                _Row('담당 기사', technician?['name']?.toString() ?? '배정 예정'),
                                const _Row('작업 내용', '점검 및 수리'),
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
