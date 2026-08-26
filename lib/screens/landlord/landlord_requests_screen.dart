import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/status_filter_button.dart';

/// "임대인 - 수리요청관리": 전체 수리 요청을 상태별로 묶어서 보여준다.
class LandlordRequestsScreen extends StatefulWidget {
  const LandlordRequestsScreen({super.key});

  @override
  State<LandlordRequestsScreen> createState() => _LandlordRequestsScreenState();
}

class _LandlordRequestsScreenState extends State<LandlordRequestsScreen> {
  List<Map<String, dynamic>>? _requests;
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = '전체';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await LandlordService.instance.getRequests();
      setState(() {
        _requests = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '요청 목록을 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  // 이 화면의 섹션 헤더(승인 대기/수리 대기/완료)를 나누는 용도의 그룹핑이다.
  // 개별 뱃지 문구/색은 category_helpers.dart의 requestStatusLabel/requestStatusColor를
  // 따로 써서 request_detail_screen.dart와 정확히 같은 표시를 보장한다 — 예전에는
  // 이 그룹명을 뱃지에도 그대로 썼는데, 그러면 rejected가 이 화면에서는 "완료"(회색)로,
  // 상세 화면에서는 "거절됨"(빨강)으로 서로 다르게 보이는 문제가 있었다.
  //
  // 백엔드 reports.status는 pending/approved/rejected 세 값만 준다
  // (landlord.controller.ts approveRequest 확인함). rejected는 더 이상 처리할
  // 게 없는 상태라 "완료" 그룹으로 묶는다.
  String _effectiveStatus(Map<String, dynamic> r) {
    final status = r['status']?.toString().toLowerCase() ?? '';
    final quotes = r['quotes'] as List?;
    final hasSelectedQuote = quotes?.any((q) => (q is Map) && q['status'] == 'selected') ?? false;
    if (hasSelectedQuote && (status.isEmpty || status == 'pending')) {
      return 'approved';
    }
    return status;
  }

  String _statusGroup(Map<String, dynamic> r) {
    final status = _effectiveStatus(r);
    if (status == 'rejected' || status.contains('완료') || status == 'completed' || status == 'done') return '완료';
    if (status.contains('수리') || status.contains('진행') || status == 'in_progress' || status == 'approved') return '수리 대기';
    return '승인 대기';
  }

  @override
  Widget build(BuildContext context) {
    final all = _requests ?? const [];
    final grouped = <String, List<Map<String, dynamic>>>{'승인 대기': [], '수리 대기': [], '완료': []};
    for (final r in all) {
      final group = _statusGroup(r);
      if (_filter != '전체' && _filter != group) continue;
      grouped[group]!.add(r);
    }
    // 필터 시트에 보여줄 개수는 현재 _filter와 무관하게 항목별 전체 개수여야
    // 한다 — 위 grouped는 이미 _filter로 걸러진 뒤라 그대로 쓰면 안 된다.
    final counts = <String, int>{'전체': all.length, '승인 대기': 0, '수리 대기': 0, '완료': 0};
    for (final r in all) {
      final group = _statusGroup(r);
      counts[group] = (counts[group] ?? 0) + 1;
    }

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
                  children: _isLoading
                      ? const [
                          SizedBox(height: 80),
                          Center(child: CircularProgressIndicator()),
                        ]
                      : _errorMessage != null
                          ? [
                              const SizedBox(height: 80),
                              Center(child: Text(_errorMessage!, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed))),
                            ]
                          : [
                              Text('수리 요청 관리', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                              const SizedBox(height: 12),
                              StatusFilterButton(
                                title: '상태',
                                filters: const ['전체', '승인 대기', '수리 대기', '완료'],
                                selected: _filter,
                                counts: counts,
                                onSelected: (f) => setState(() => _filter = f),
                              ),
                              const SizedBox(height: 20),
                              for (final group in ['승인 대기', '수리 대기', '완료'])
                                if (grouped[group]!.isNotEmpty) ...[
                                  Text(group, style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
                                  const SizedBox(height: 8),
                                  for (final r in grouped[group]!) ...[
                                    _RequestRow(
                                      title: formatRequestTitle(r),
                                      subtitle: formatRequestSubtitle(r),
                                      badgeText: requestStatusLabel(_effectiveStatus(r)),
                                      badgeColor: requestStatusColor(_effectiveStatus(r)),
                                      onTap: () => context.push('/landlord/requests/${r['id']}').then((_) => _load()),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              if (grouped.values.every((list) => list.isEmpty))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text(
                                      _filter == '전체' ? '수리 요청이 없습니다.' : '$_filter 상태의 요청이 없습니다.',
                                      style: AppTextStyles.bodyRegular14(color: AppColors.gray6),
                                    ),
                                  ),
                                ),
                            ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/landlord', reportsPath: '/landlord/requests'),
          ],
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String badgeText;
  final Color badgeColor;
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(999)),
              child: Text(badgeText, style: AppTextStyles.bodySemiBold12(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
