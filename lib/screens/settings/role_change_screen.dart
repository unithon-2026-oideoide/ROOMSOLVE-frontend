import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/role_routes.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

class _RoleOption {
  const _RoleOption(this.role, this.title, this.description);
  final UserRole role;
  final String title;
  final String description;
}

const _roleOptions = [
  _RoleOption(UserRole.tenant, '세입자', '수리 문제를 신고하고 해결 진행 상황을 확인합니다.'),
  _RoleOption(UserRole.landlord, '임대인', '수리 요청을 검토하고 수리 진행을 승인 관리합니다.'),
  _RoleOption(UserRole.technician, '수리기사', '배정된 수리 작업을 확인하고 현장 처리를 등록합니다.'),
];

/// "사용자 유형 변경 화면". PATCH /api/users/{id}/role를 호출해 서버에 반영한다
/// (AuthProvider.updateRole 경유).
///
/// 유형 선택을 showModalBottomSheet로 띄웠다가, 바텀시트가 닫히는 애니메이션이
/// 끝나기 전에 context.go()로 라우트 스택 전체를 교체하면서 Flutter 렌더링
/// 엔진의 '!semantics.parentDataDirty' assertion으로 앱이 죽는 문제가 있었다.
/// 한 프레임만 지연시켜도 재현됐던 걸 보면 애니메이션 시간과의 경합 문제라
/// 딜레이를 늘리는 식으로는 기기마다 다르게 깨질 수 있어, 아예 모달을 없애고
/// 화면 안에 카드로 유형을 고르게 바꿨다.
class RoleChangeScreen extends StatefulWidget {
  const RoleChangeScreen({super.key});

  @override
  State<RoleChangeScreen> createState() => _RoleChangeScreenState();
}

class _RoleChangeScreenState extends State<RoleChangeScreen> {
  UserRole? _pendingRole;
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _requestChange() async {
    final selected = _pendingRole;
    if (selected == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().updateRole(selected);
      if (mounted) {
        // AuthProvider.updateRole()의 notifyListeners()가 router.dart의
        // refreshListenable을 통해 GoRouter를 한 번 자동으로 리프레시시킨다.
        // 그 직후 같은 프레임에서 context.go()로 또 라우트를 바꾸면 두 번의
        // 라우터 변경이 겹쳐서 '!semantics.parentDataDirty'로 죽을 수 있다.
        // 다음 프레임으로 미뤄 자동 리프레시가 먼저 끝나게 한다.
        final target = homePathForRole(selected);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(target);
        });
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = '유형 변경 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _roleCard(_RoleOption option, UserRole currentRole) {
    final isCurrent = option.role == currentRole;
    final isPending = option.role == _pendingRole;
    return GestureDetector(
      onTap: isCurrent ? null : () => setState(() => _pendingRole = option.role),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isPending ? AppColors.brandMain : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppColors.dropShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.title, style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                  const SizedBox(height: 4),
                  Text(option.description, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                ],
              ),
            ),
            if (isCurrent)
              Text('현재 유형', style: AppTextStyles.captionRegular10(color: AppColors.gray5))
            else
              Icon(
                isPending ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isPending ? AppColors.brandMain : AppColors.gray3,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;

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
                    Text('사용자 유형 변경', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 8),
                    Text(
                      '유형을 변경하면 서비스 이용 범위와 시작 화면이 달라집니다. 아래에서 새 유형을 선택한 뒤 변경 요청을 눌러주세요.',
                      style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                    ),
                    const SizedBox(height: 16),
                    for (final option in _roleOptions) ...[
                      _roleCard(option, role),
                      const SizedBox(height: 12),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: (_isSubmitting || _pendingRole == null) ? null : _requestChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          disabledBackgroundColor: AppColors.gray3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text('유형 변경 요청', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AppBottomNav(
              current: AppBottomNavTab.settings,
              homePath: homePathForRole(role),
              reportsPath: requestsPathForRole(role),
            ),
          ],
        ),
      ),
    );
  }
}
