import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_routes.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

const _roleOptions = [UserRole.tenant, UserRole.landlord, UserRole.technician];

/// "사용자 유형 변경 화면". 유형 변경 전용 백엔드 API가 없어
/// AuthProvider.updateRole로 로컬 상태만 갱신한다.
class RoleChangeScreen extends StatelessWidget {
  const RoleChangeScreen({super.key});

  Future<void> _requestChange(BuildContext context) async {
    final auth = context.read<AuthProvider>();
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
    if (selected == null || !context.mounted) return;
    auth.updateRole(selected);
    context.go(homePathForRole(selected));
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
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => _requestChange(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('유형 변경 요청', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
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
