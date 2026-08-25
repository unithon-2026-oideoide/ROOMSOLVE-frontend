import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

const _categoryOptions = ['배관·누수', '전기·조명', '냉난방 기기', '도어락·잠금장치', '창문·유리'];
const _defaultSelectedCategories = {'배관·누수', '전기·조명', '도어락·잠금장치'};

class AutoApprovalSettingScreen extends StatefulWidget {
  const AutoApprovalSettingScreen({super.key});

  @override
  State<AutoApprovalSettingScreen> createState() => _AutoApprovalSettingScreenState();
}

class _AutoApprovalSettingScreenState extends State<AutoApprovalSettingScreen> {
  final _maxAmountController = TextEditingController();
  final Set<String> _selectedCategories = {..._defaultSelectedCategories};
  bool _excludeAiRisk = true;
  bool _excludeFrequentTenant = true;
  bool _excludeNoPhoto = true;
  bool _isSubmitting = false;
  String? _message;

  @override
  void dispose() {
    _maxAmountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await LandlordService.instance.setAutoApprovalPolicy(policy: {
        'enabled': _selectedCategories.isNotEmpty,
        'maxAmount': num.tryParse(_maxAmountController.text) ?? 0,
        'categories': _selectedCategories.toList(),
        'excludeAiRisk': _excludeAiRisk,
        'excludeFrequentTenant': _excludeFrequentTenant,
        'excludeNoPhoto': _excludeNoPhoto,
      });
      setState(() => _message = '설정이 저장되었습니다.');
    } on ApiException catch (e) {
      setState(() => _message = e.message);
    } catch (e) {
      setState(() => _message = '설정 저장 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _checkboxRow(String label) {
    final checked = _selectedCategories.contains(label);
    return GestureDetector(
      onTap: () => setState(() {
        if (checked) {
          _selectedCategories.remove(label);
        } else {
          _selectedCategories.add(label);
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
              child: SingleChildScrollView(
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
                          for (final c in _categoryOptions) _checkboxRow(c),
                          const SizedBox(height: 8),
                          Text('선택한 카테고리의 요청만 자동 처리 대상이 됩니다.', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
