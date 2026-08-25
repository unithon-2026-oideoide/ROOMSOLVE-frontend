import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

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

  // 백엔드 reports.status는 pending/approved/rejected 세 값만 준다
  // (landlord.controller.ts approveRequest 확인함). rejected는 더 이상 처리할
  // 게 없는 상태라 "완료" 그룹으로 묶는다.
  String _statusGroup(Map<String, dynamic> r) {
    final status = r['status']?.toString().toLowerCase() ?? '';
    if (status == 'rejected' || status.contains('완료') || status == 'completed' || status == 'done') return '완료';
    if (status.contains('진행') || status == 'in_progress' || status == 'approved') return '진행 중';
    return '승인 대기';
  }

  Color _statusColor(String group) {
    switch (group) {
      case '승인 대기':
        return AppColors.accentGreen;
      case '진행 중':
        return AppColors.brandMain;
      default:
        return AppColors.gray5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _requests ?? const [];
    final grouped = <String, List<Map<String, dynamic>>>{'승인 대기': [], '진행 중': [], '완료': []};
    for (final r in all) {
      final group = _statusGroup(r);
      if (_filter != '전체' && _filter != group) continue;
      grouped[group]!.add(r);
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                // RefreshIndicator의 직접 자식은 항상 같은 Scrollable(ListView)이어야
                // 한다. 상태별로 다른 위젯으로 통째로 바꿔치기하면 Flutter 렌더링
                // 엔진이 '!semantics.parentDataDirty' assertion으로 죽는 경우가 있어,
                // 상태별 콘텐츠도 전부 ListView 안의 아이템으로 둔다.
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('수리 요청 관리', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                                  _FilterDropdown(value: _filter, onChanged: (v) => setState(() => _filter = v)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              for (final group in ['승인 대기', '진행 중', '완료'])
                                if (grouped[group]!.isNotEmpty) ...[
                                  Text(group, style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
                                  const SizedBox(height: 8),
                                  for (final r in grouped[group]!) ...[
                                    _RequestRow(
                                      title: r['title']?.toString() ?? r['category']?.toString() ?? '수리 요청 #${r['id']}',
                                      subtitle: r['unit']?.toString() ?? r['location']?.toString() ?? '',
                                      badgeText: group,
                                      badgeColor: _statusColor(group),
                                      onTap: () => context.push('/landlord/requests/${r['id']}'),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  const SizedBox(height: 12),
                                ],
                              if (all.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text('등록된 수리 요청이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  static const _options = ['전체', '승인 대기', '진행 중', '완료'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.expand_more, size: 16, color: AppColors.gray8),
          style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
          items: [for (final o in _options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: (v) => onChanged(v ?? '전체'),
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
              child: Text(badgeText, style: AppTextStyles.bodyRegular12(color: AppColors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
