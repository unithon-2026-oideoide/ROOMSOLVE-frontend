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

const _roleOptions = [UserRole.tenant, UserRole.landlord, UserRole.technician];

/// "사용자 유형 변경 화면". PATCH /api/users/{id}/role를 호출해 서버에 반영한다
/// (AuthProvider.updateRole 경유).
class RoleChangeScreen extends StatefulWidget {
  const RoleChangeScreen({super.key});

  @override
  State<RoleChangeScreen> createState() => _RoleChangeScreenState();
}

class _RoleChangeScreenState extends State<RoleChangeScreen> {
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _requestChange() async {
    final selected = await showModalBottomSheet<UserRole>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final role in _roleOptions)
              ListTile(
                title: Text(roleLabel(role)),
                onTap: () => Navigator.pop(context, role),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthProvider>().updateRole(selected);
      if (mounted) {
        // 바텀시트가 닫히는 애니메이션이 끝나기 전에 context.go로 라우트
        // 스택 전체를 교체하면 Flutter 렌더링 엔진이
        // '!semantics.parentDataDirty' assertion으로 죽는 경우가 있어,
        // 다음 프레임으로 미뤄 현재 프레임/시맨틱스 트리가 먼저 정리되게 한다.
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
                          Text('현재 유형', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                          const SizedBox(height: 8),
                          Text(roleLabel(role), style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '유형을 변경하면 서비스 이용 범위와 시작 화면이 달라집니다. 변경 요청을 제출하면 유형 선택 화면으로 이동합니다.',
                      style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _requestChange,
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
