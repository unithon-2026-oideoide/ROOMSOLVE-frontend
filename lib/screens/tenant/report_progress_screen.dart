import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

enum _StepState { done, current, pending }

class _TimelineStep {
  const _TimelineStep({required this.title, required this.lines, required this.state});
  final String title;
  final List<String> lines;
  final _StepState state;
}

/// "세입자 - 수리 진행 현황" 화면.
/// GET /api/repair/timeline로 실제 상태 이력을 가져와 현재 단계를 판단한다.
/// 신고 접수/해결 경로 안내/임대인 승인 세 단계는 이 이력에 대응하는 상세
/// API가 없어(백엔드는 scheduled/confirmed/in_progress/done만 기록) 신고가
/// 존재하고 분석까지 끝났다는 사실만으로 완료 표시한다.
class ReportProgressScreen extends StatefulWidget {
  const ReportProgressScreen({super.key, required this.report});

  final Report report;

  @override
  State<ReportProgressScreen> createState() => _ReportProgressScreenState();
}

class _ReportProgressScreenState extends State<ReportProgressScreen> {
  String? _currentStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await RepairService.instance.getTimeline(widget.report.id);
      if (mounted) setState(() => _currentStatus = result.currentStatus);
    } on ApiException {
      // 이력이 없거나 조회에 실패하면 report.status 기반 추정으로 대체한다.
    } catch (_) {
      // 위와 동일.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _isCompleted {
    final status = _currentStatus ?? widget.report.status;
    return status == 'done' || status == 'completed' || status == '완료';
  }

  bool get _isVisitConfirmed {
    final status = _currentStatus ?? widget.report.status;
    return status == 'scheduled' || status == 'confirmed' || status == 'in_progress' || _isCompleted;
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    final steps = [
      const _TimelineStep(title: '신고 접수', lines: ['신고가 정상적으로 접수되었습니다.'], state: _StepState.done),
      const _TimelineStep(
        title: '해결 경로 안내',
        lines: ['AI가 수리 방법과 처리 절차를 안내했습니다.'],
        state: _StepState.done,
      ),
      const _TimelineStep(
        title: '임대인 승인',
        lines: ['집주인이 수리 요청을 승인했습니다.'],
        state: _StepState.done,
      ),
      _TimelineStep(
        title: '수리기사 배정 및 방문 일정',
        lines: [_currentStatus ?? report.status ?? '방문 일정을 조율 중입니다.'],
        state: _isCompleted
            ? _StepState.done
            : (_isVisitConfirmed ? _StepState.done : _StepState.current),
      ),
      _TimelineStep(
        title: '수리 완료 확인',
        lines: const ['방문 후 완료 여부를 확인합니다.'],
        state: _isCompleted ? _StepState.done : (_isVisitConfirmed ? _StepState.current : _StepState.pending),
      ),
    ];

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
                          Text('수리 진행 현황', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                          const SizedBox(height: 16),
                          Container(
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
                                      Text(
                                        report.category ?? report.description ?? '분류 대기 중',
                                        style: AppTextStyles.bodyRegular16(color: AppColors.gray8),
                                      ),
                                      const SizedBox(height: 4),
                                      if (report.createdAt != null)
                                        Text(
                                          '접수 ${report.createdAt!.year}.${report.createdAt!.month.toString().padLeft(2, '0')}.${report.createdAt!.day.toString().padLeft(2, '0')}',
                                          style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _isCompleted ? '수리 완료' : '방문 예정',
                                  style: AppTextStyles.bodyRegular14(color: AppColors.brandLight),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('진행 단계', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                          const SizedBox(height: 12),
                          for (final step in steps) ...[
                            _StepCard(step: step),
                            const SizedBox(height: 12),
                          ],
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
                                Text('다음 단계 안내', style: AppTextStyles.subtitleSemiBold16(color: AppColors.gray8)),
                                const SizedBox(height: 8),
                                Text(
                                  _isCompleted
                                      ? '수리가 완료되었습니다. 완료 결과는 신고 내역에서 확인할 수 있습니다.'
                                      : '방문 당일 집에 계셔야 하며, 수리 완료 후 앱에서 결과를 확인할 수 있습니다.',
                                  style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                                ),
                              ],
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

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step});
  final _TimelineStep step;

  @override
  Widget build(BuildContext context) {
    late final Color badgeColor;
    late final Widget icon;
    switch (step.state) {
      case _StepState.done:
        badgeColor = AppColors.accentGreen;
        icon = const Icon(Icons.check, size: 14, color: AppColors.white);
        break;
      case _StepState.current:
        badgeColor = AppColors.accentYellow;
        icon = const Icon(Icons.arrow_forward, size: 14, color: AppColors.white);
        break;
      case _StepState.pending:
        badgeColor = AppColors.gray3;
        icon = const Icon(Icons.circle_outlined, size: 12, color: AppColors.gray8);
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppColors.dropShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
            child: icon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.title, style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                const SizedBox(height: 8),
                for (final line in step.lines)
                  Text(line, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
