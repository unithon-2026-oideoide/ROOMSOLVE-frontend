import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/role_routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/screen_header.dart';

/// "임대인 연결" 화면. 세입자가 임대인에게 받은 초대 코드를 입력해
/// PATCH /api/users/link-landlord를 호출한다. 연결돼야 신고 접수(POST
/// /api/reports)가 성공한다 — 백엔드가 landlord_id를 이 연결값으로 대신 채우기
/// 때문이다(회원가입 시 이미 입력했다면 다시 쓸 필요는 없고, 나중에 바꾸거나
/// 처음 연결할 때 여기서 하면 된다).
class LandlordLinkScreen extends StatefulWidget {
  const LandlordLinkScreen({super.key});

  @override
  State<LandlordLinkScreen> createState() => _LandlordLinkScreenState();
}

class _LandlordLinkScreenState extends State<LandlordLinkScreen> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = '초대 코드를 입력해주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().linkLandlord(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('임대인과 연결되었습니다.')),
        );
        _codeController.clear();
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = '연결 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final linked = auth.currentUser?.linkedLandlordId != null;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenHeader(title: '임대인 연결'),
                    const SizedBox(height: 8),
                    Text(
                      '임대인에게 받은 초대 코드를 입력하면, 이후 신고할 때 자동으로 해당 임대인에게 접수됩니다.',
                      style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                    ),
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
                            child: Text('현재 상태', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                          ),
                          Text(
                            linked ? '연결됨' : '연결된 임대인 없음',
                            style: AppTextStyles.bodySemiBold14(
                              color: linked ? AppColors.accentGreen : AppColors.gray6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: TextField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        style: AppTextStyles.bodyRegular14(color: AppColors.black),
                        decoration: InputDecoration(
                          hintText: '초대 코드 (예: AB12CD)',
                          hintStyle: AppTextStyles.bodyRegular14(color: AppColors.gray5),
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                    ],
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
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
                              : Text(linked ? '다른 코드로 다시 연결' : '연결하기',
                                  style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNav(
              current: AppBottomNavTab.settings,
              homePath: homePathForRole(auth.role),
              reportsPath: requestsPathForRole(auth.role),
            ),
          ],
        ),
      ),
    );
  }
}
