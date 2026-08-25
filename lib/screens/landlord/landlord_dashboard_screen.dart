import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../providers/auth_provider.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({super.key});

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> {
  List<Map<String, dynamic>>? _requests;
  List<Map<String, dynamic>>? _properties;
  bool _isLoading = true;
  String? _errorMessage;

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
      final results = await Future.wait([
        LandlordService.instance.getRequests(),
        LandlordService.instance.getProperties(),
      ]);
      setState(() {
        _requests = results[0];
        _properties = results[1];
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  bool _isVacant(Map<String, dynamic> unit) {
    final status = unit['status']?.toString().toLowerCase();
    return status == 'vacant' || status == 'empty' || status == '공실';
  }

  bool _isPending(Map<String, dynamic> r) {
    final status = r['status']?.toString().toLowerCase() ?? '';
    final quotes = r['quotes'] as List?;
    final hasSelectedQuote = quotes?.any((q) => (q is Map) && q['status'] == 'selected') ?? false;
    if (hasSelectedQuote || status == 'approved' || status == 'in_progress' || status == 'done' || status == 'completed' || status == 'rejected') {
      return false;
    }
    return status.isEmpty || status == 'pending';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final userName = user?.name ?? user?.email.split('@').first ?? '사용자';
    final properties = _properties ?? const [];
    final vacant = properties.where(_isVacant).length;
    final occupied = properties.length - vacant;
    final pendingRequests = (_requests ?? const []).where(_isPending).toList();

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
                // 한다. 로딩 중일 때 Center(CircularProgressIndicator)로 통째로
                // 바꿔치기하면(=Scrollable이 있다가 없다가 함) 라우트 전환과 겹칠 때
                // Flutter 렌더링 엔진이 '!semantics.parentDataDirty' assertion으로
                // 죽는 경우가 있어, 로딩 스피너도 ListView 안의 아이템으로 둔다.
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  children: _isLoading
                      ? const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ]
                      : [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                            ),
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
                          const SizedBox(height: 20),
                          _SectionCard(
                            title: '임대 관리 현황',
                            child: Row(
                              children: [
                                Expanded(child: _StatBox(label: '관리 호실', value: '${properties.length}')),
                                const SizedBox(width: 12),
                                Expanded(child: _StatBox(label: '입주 중', value: '$occupied')),
                                const SizedBox(width: 12),
                                Expanded(child: _StatBox(label: '공실', value: '$vacant')),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('처리 대기 수리 요청', style: AppTextStyles.bodySemiBold16(color: const Color(0xFF212121))),
                          const SizedBox(height: 12),
                          if (pendingRequests.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text('처리 대기 중인 요청이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
                            )
                          else
                            for (final r in pendingRequests.take(3)) ...[
                              _PendingRequestCard(
                                title: formatRequestTitle(r),
                                subtitle: formatRequestSubtitle(r).isNotEmpty ? formatRequestSubtitle(r) : '승인이 필요합니다.',
                                // 상세 화면에서 승인하면 context.pop()으로 돌아오는데, 이 화면
                                // State는 그대로 재사용되므로 승인 전 _requests가 남아있는다.
                                // 돌아왔을 때 다시 불러와 "처리 대기 수리 요청" 카드가 갱신되게 한다.
                                onTap: () => context.push('/landlord/requests/${r['id']}').then((_) => _load()),
                              ),
                              const SizedBox(height: 12),
                            ],
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 47,
                            child: ElevatedButton(
                              onPressed: () => context.push('/landlord/requests'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                                elevation: 0,
                              ),
                              child: Text('수리 요청 전체 보기', style: AppTextStyles.subtitleBold18(color: AppColors.white)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('호실 관리', style: AppTextStyles.subtitleBold18(color: const Color(0xFF212121))),
                          const SizedBox(height: 12),
                          _SectionCard(
                            title: '',
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('호실 목록 및 계약 현황', style: AppTextStyles.bodySemiBold16(color: const Color(0xFF212121))),
                                      const SizedBox(height: 8),
                                      Text('${properties.length}개 호실 · 공실 $vacant개', style: AppTextStyles.bodyRegular12(color: const Color(0xFF212121))),
                                    ],
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => context.push('/landlord/units'),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: AppColors.gray2,
                                    side: BorderSide.none,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(31)),
                                  ),
                                  child: Text('관리', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                                ),
                              ],
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.dropShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.dropShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray7)),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.subtitleBold18(color: const Color(0xFF212121))),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({required this.title, required this.subtitle, required this.onTap});
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.dropShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyRegular16(color: const Color(0xFF212121))),
                const SizedBox(height: 8),
                Text(subtitle, style: AppTextStyles.bodyRegular12(color: const Color(0xFF212121))),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.gray2,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text('확인', style: AppTextStyles.bodyRegular14(color: const Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }
}
