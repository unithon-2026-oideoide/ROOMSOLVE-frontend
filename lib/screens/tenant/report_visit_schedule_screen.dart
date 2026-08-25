import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/report.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// "세입자 - 방문 일정 확정" 화면.
/// GET /api/repair/schedule?reportId=로 실제 확정 일정을 가져온다. 일정이
/// 아직 없으면(빈 배열) 디자인의 예시 값으로 대체해 보여준다.
class ReportVisitScheduleScreen extends StatefulWidget {
  const ReportVisitScheduleScreen({super.key, required this.report});

  final Report report;

  @override
  State<ReportVisitScheduleScreen> createState() => _ReportVisitScheduleScreenState();
}

class _ReportVisitScheduleScreenState extends State<ReportVisitScheduleScreen> {
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
      final schedules = await RepairService.instance.getSchedules(reportId: widget.report.id);
      // schedules가 빈 배열인 건 조회 성공 + "아직 일정이 없음"이라 정상 케이스다.
      // 이 경우에만 아래 예시 값으로 대체한다. 조회 자체가 실패한 경우(아래 catch)는
      // 다르게 다뤄야 한다 — 실패를 조용히 삼키고 예시 값을 "확정된 일정"인 것처럼
      // 보여주면, 세입자가 실제로는 정해지지 않은 날짜에 집에서 기다리게 된다.
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
    final report = widget.report;
    final scheduledAt = _schedule?['scheduled_at'] != null ? DateTime.tryParse(_schedule!['scheduled_at'].toString())?.toLocal() : null;
    final technician = _schedule?['technician'] as Map<String, dynamic>?;
    // 조회는 성공했지만 아직 일정이 없는(스케줄이 하나도 없거나 확정 시각이
    // 없는) 정상 케이스다. 예전에는 이 경우에도 "2025년 8월 14일" 같은 디자인
    // 예시 값을 실제 확정 일정인 것처럼 보여줘서, 세입자가 실제로는 정해지지
    // 않은 날짜에 집에서 기다리게 될 수 있었다.
    final hasSchedule = scheduledAt != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                                      '업체가 방문 가능 시간을 제안하고 임대인이 견적을 선택하면 이 화면에 일정이 표시됩니다.',
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
                                const SizedBox(height: 12),
                                _InfoRow(
                                  label: '날짜',
                                  value: '${scheduledAt.year}년 ${scheduledAt.month}월 ${scheduledAt.day}일',
                                ),
                                _InfoRow(
                                  label: '시간',
                                  value:
                                      '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}',
                                ),
                                _InfoRow(label: '담당 기사', value: technician?['name']?.toString() ?? '배정 예정'),
                                _InfoRow(
                                  label: '작업 내용',
                                  value: report.category != null ? '${categoryLabel(report.category)} 점검 및 수리' : '점검 및 수리',
                                ),
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
