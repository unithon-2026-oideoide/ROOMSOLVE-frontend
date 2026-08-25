import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/category_helpers.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

class AutoApprovalSettingScreen extends StatefulWidget {
  const AutoApprovalSettingScreen({super.key});

  @override
  State<AutoApprovalSettingScreen> createState() => _AutoApprovalSettingScreenState();
}

class _AutoApprovalSettingScreenState extends State<AutoApprovalSettingScreen> {
  final _maxAmountController = TextEditingController();
  // 백엔드 REPAIR_CATEGORIES 코드(plumbing 등)를 담는다 — 예전에는 이 화면만
  // 쓰는 별도의 한글 문자열('배관·누수' 등)을 담아서, 저장을 눌러도 백엔드가
  // 이해하는 category 값과 전혀 안 맞아 실제로는 아무 카테고리도 저장된 적이
  // 없었다.
  final Set<String> _selectedCategories = {};
  bool _excludeAiRisk = true;
  bool _excludeFrequentTenant = true;
  bool _excludeNoPhoto = true;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _maxAmountController.dispose();
    super.dispose();
  }

  // 저장된 카테고리별 한도를 불러와 체크박스/금액을 채운다. 예전에는 이 조회
  // 자체가 없어서(백엔드에 GET이 없었음) 화면을 열 때마다 하드코딩된 기본값으로
  // 리셋됐고, "설정 저장"을 누르면 그 기본값이 기존 설정을 덮어썼다.
  Future<void> _load() async {
    try {
      final policies = await LandlordService.instance.getAutoApprovalPolicies();
      if (!mounted) return;
      setState(() {
        _selectedCategories
          ..clear()
          ..addAll(policies.map((p) => p['category']?.toString()).whereType<String>());
        // 화면은 카테고리마다 다른 금액을 따로 보여줄 UI가 없다(디자인상 금액 한도가
        // 하나) — 저장된 값이 있으면 그중 하나를 대표로 보여준다. 카테고리별로
        // 다른 금액을 저장해 뒀다면(예: API로 직접 넣은 경우) 이 화면에서 "저장"을
        // 누르는 순간 전부 같은 금액으로 통일된다.
        if (policies.isNotEmpty) {
          final limit = policies.first['auto_approve_limit'];
          if (limit != null) _maxAmountController.text = limit.toString();
        }
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() { _message = e.message; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _message = '설정을 불러오지 못했습니다: $e'; _isLoading = false; });
    }
  }

  Future<void> _save() async {
    final limit = int.tryParse(_maxAmountController.text.trim());
    if (limit == null || limit < 0) {
      setState(() => _message = '자동 승인 금액 한도를 올바르게 입력해주세요.');
      return;
    }
    if (_selectedCategories.isEmpty) {
      setState(() => _message = '자동 처리를 허용할 카테고리를 최소 1개 선택해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      // 백엔드는 카테고리 하나씩만 저장한다(POST가 category 단일 값을 받음) —
      // 선택한 카테고리 수만큼 순서대로 호출한다. 예전 선택에서 뺀 카테고리의
      // 기존 저장값은 삭제 API가 없어 이 화면에서는 지울 수 없다.
      for (final category in _selectedCategories) {
        await LandlordService.instance.setAutoApprovalPolicy(category: category, autoApproveLimit: limit);
      }
      setState(() => _message = '설정이 저장되었습니다.');
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = '설정 저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _checkboxRow(String category, String label) {
    final checked = _selectedCategories.contains(category);
    return GestureDetector(
      onTap: () => setState(() {
        if (checked) {
          _selectedCategories.remove(category);
        } else {
          _selectedCategories.add(category);
        }
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: checked ? AppColors.brandDark : AppColors.white,
                border: checked ? null : Border.all(color: const Color(0xFFB3B3B3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: checked ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
          ],
        ),
      ),
    );
  }

  Widget _exceptionSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8))),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.white, activeTrackColor: AppColors.brandDark),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('자동처리 한도 설정', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                    const SizedBox(height: 8),
                    Text(
                      '수리 요청이 아래 조건을 모두 충족하면 임대인 승인 없이 자동으로 처리됩니다.',
                      style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                    ),
                    const SizedBox(height: 20),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('자동 승인 금액 한도', style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8)],
                            ),
                            child: TextField(
                              controller: _maxAmountController,
                              keyboardType: TextInputType.number,
                              style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: '최대 자동 승인 금액 (원)',
                                hintStyle: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                                suffixIcon: const Icon(Icons.expand_more, size: 16, color: AppColors.gray8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '설정 금액 이하의 수리 요청은 자동으로 승인되어 수리기사에게 전달됩니다.',
                            style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('자동 처리 허용 카테고리', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                          const SizedBox(height: 8),
                          for (final entry in categoryLabels.entries) _checkboxRow(entry.key, entry.value),
                          const SizedBox(height: 8),
                          Text('선택한 카테고리의 요청만 자동 처리 대상이 됩니다.', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // landlord_auto_approval_policy 테이블에 이 예외 조건들을 저장할
                    // 컬럼이 없다 — 백엔드가 category/auto_approve_limit만 받는다.
                    // 그래서 이 카드의 스위치는 notification_settings_screen.dart와
                    // 같은 이유로 로컬 상태만 바꾸고 서버에는 반영되지 않는다.
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('예외 처리 기준', style: AppTextStyles.bodySemiBold16(color: AppColors.black)),
                          _exceptionSwitch('AI 위험 판단 요청은 자동 처리 제외', _excludeAiRisk, (v) => setState(() => _excludeAiRisk = v)),
                          _exceptionSwitch(
                            '동일 세입자 월 2회 초과 요청은 자동 처리 제외',
                            _excludeFrequentTenant,
                            (v) => setState(() => _excludeFrequentTenant = v),
                          ),
                          _exceptionSwitch('사진 미첨부 요청은 자동 처리 제외', _excludeNoPhoto, (v) => setState(() => _excludeNoPhoto = v)),
                          const SizedBox(height: 4),
                          Text('예외 기준에 해당하는 요청은 임대인 검토 후 승인됩니다.', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_message != null) ...[
                      Text(_message!, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text('설정 저장', style: AppTextStyles.bodyRegular14(color: AppColors.white)),
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

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8)],
      ),
      child: child,
    );
  }
}
