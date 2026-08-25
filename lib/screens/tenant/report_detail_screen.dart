import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../models/report.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

String _formatDateTime(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return isoString;
  final local = dt.toLocal();
  return '${local.year}년 ${local.month}월 ${local.day}일 ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// "신고 내역 상세 화면". 진행 타임라인의 뒷부분(방문 일정~수리 완료)은
/// GET /api/repair/timeline로 실제 이력을 가져와 표시한다. Report 모델에
/// 없는 위치/긴급도/비용 부담 등 일부 필드는 데이터가 있으면 쓰고, 없으면
/// 안내 텍스트로 대체한다.
class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, required this.report});

  final Report report;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<Map<String, dynamic>>? _timeline;
  String? _currentStatus;
  bool _isLoadingTimeline = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    try {
      final result = await RepairService.instance.getTimeline(widget.report.id);
      if (mounted) {
        setState(() {
          _timeline = result.timeline;
          _currentStatus = result.currentStatus;
        });
      }
    } on ApiException {
      // 이력이 없으면(400/404 등) 아래 정적 안내로 대체한다.
    } catch (_) {
      // 위와 동일.
    } finally {
      if (mounted) setState(() => _isLoadingTimeline = false);
    }
  }

  bool get _isCompleted {
    final status = _currentStatus ?? widget.report.status;
    return status == 'completed' || status == 'done' || status == '완료';
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    // 거절은 repair_status_timeline과 무관하게 reports.status 자체가 갖는 상태라
    // 다른 무엇보다 우선한다 — 거절된 신고는 일정/진행 이력이 아예 없다.
    final rejected = report.isRejected;
    final badgeLabel = rejected
        ? '거절됨'
        : (_isCompleted ? '완료' : (_currentStatus != null ? repairStatusLabel(_currentStatus) : report.statusLabel));
    final badgeColor = rejected ? AppColors.accentRed : AppColors.brandLight;

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
                        Expanded(
                          child: Text(
                            formatReportTitle(report.category, report.description),
                            style: AppTextStyles.subtitleBold22(color: AppColors.black),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
                          child: Text(
                            badgeLabel,
                            style: AppTextStyles.bodyRegular12(color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '신고 접수 ${report.createdAt != null ? '${report.createdAt!.year}년 ${report.createdAt!.month}월 ${report.createdAt!.day}일' : '날짜 미상'} · 신고 번호 #${report.id}',
                      style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: '핵심 요약',
                      child: Column(
                        children: [
                          _Row('문제 유형', categoryLabel(report.category)),
                          _Row('긴급도', severityLabel(report.severity)),
                          // 가전 하자는 소유 관계·보증기간에 따라 부담 주체가 갈린다
                          // (report_service.dart의 [가전 하자 판정] 태그 참고). 그
                          // 판정이 없는 일반 하자에서만 "임대인 부담"이 사실이므로,
                          // 판정이 있으면 그 결과를, 없으면 확정 전임을 보여준다 —
                          // 예전에는 판정 결과와 무관하게 항상 "임대인 부담"으로
                          // 고정 표시해서, 임차인 부담·제조사 보증 대상인 가전도
                          // 임대인이 낸다고 잘못 안내했다.
                          _Row(
                            '비용 부담',
                            applianceLiabilityFromDescription(report.description) ?? '임대인 승인 후 확정',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      title: 'AI 판단',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.selfFixGuide ?? report.description ?? 'AI 판단 정보가 없습니다.',
                            style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '※ 이 판단은 사진과 설명을 바탕으로 한 참고 의견이며 확정 사실이 아닙니다.',
                            style: AppTextStyles.captionLight12(color: AppColors.gray5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('진행 타임라인', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                    const SizedBox(height: 8),
                    const _TimelineCard(title: '신고 접수', done: true, subtitle: '사진 및 상황 설명 제출 완료'),
                    const SizedBox(height: 12),
                    const _TimelineCard(title: 'AI 판단 완료', done: true, subtitle: '원인 분석 및 긴급도 산정 완료'),
                    const SizedBox(height: 12),
                    if (rejected)
                      const _TimelineCard(
                        title: '임대인 거절',
                        done: false,
                        rejected: true,
                        subtitle: '임대인이 이 신고를 거절했습니다. 자세한 사유는 임대인에게 문의해주세요.',
                      )
                    else ...[
                      _TimelineCard(
                        title: '임대인 승인',
                        done: report.status == 'approved' || _isCompleted,
                        current: report.status == null || report.status == 'pending',
                        subtitle: report.status == 'approved' || _isCompleted
                            ? '수리 진행이 승인되어 수리기사 배정 요청이 접수되었습니다.'
                            : '임대인의 승인을 기다리고 있습니다.',
                      ),
                      const SizedBox(height: 12),
                      if (_isLoadingTimeline)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_timeline != null && _timeline!.isNotEmpty)
                        for (int i = 0; i < _timeline!.length; i++) ...[
                          _TimelineCard(
                            title: repairStatusLabel(_timeline![i]['status']?.toString()),
                            done: true,
                            subtitle: _formatDateTime(_timeline![i]['changed_at']?.toString() ?? ''),
                          ),
                          const SizedBox(height: 12),
                        ]
                      else
                        _TimelineCard(
                          title: '수리 완료 확인',
                          done: _isCompleted,
                          current: !_isCompleted,
                          subtitle: _isCompleted ? '수리가 완료되었습니다.' : '일정 확정 후 진행',
                        ),
                    ],
                    if (report.photoUrls.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('신고 사진', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(report.photoUrls.first, height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                      if (report.photoUrls.length > 1) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final url in report.photoUrls.skip(1)) ...[
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(url, height: 100, fit: BoxFit.cover),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/tenant', reportsPath: '/tenant/reports'),
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
          Text(title, style: AppTextStyles.subtitleBold18(color: AppColors.black)),
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
          Expanded(child: Text(label, style: AppTextStyles.bodySemiBold14(color: AppColors.gray8))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: AppTextStyles.bodyRegular14(color: AppColors.gray7))),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.title,
    required this.subtitle,
    required this.done,
    this.current = false,
    this.rejected = false,
  });
  final String title;
  final String subtitle;
  final bool done;
  final bool current;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    final color = rejected
        ? AppColors.accentRed
        : done
            ? AppColors.accentGreen
            : (current ? AppColors.accentYellow : AppColors.gray3);
    final icon = rejected ? Icons.close : (done ? Icons.check : (current ? Icons.arrow_forward : Icons.circle_outlined));

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 14, color: done || current || rejected ? AppColors.white : AppColors.gray8),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: AppTextStyles.bodySemiBold16(color: AppColors.gray8))),
            ],
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: AppTextStyles.bodyRegular12(color: AppColors.gray7)),
        ],
      ),
    );
  }
}
