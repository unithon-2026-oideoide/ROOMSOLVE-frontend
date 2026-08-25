import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "설정 화면". 로그인/역할과 무관하게 공용으로 쓰인다.
/// 각 역할 홈 화면에 있던 로그아웃 버튼을 여기로 옮겨왔다 — 디자인에는
/// 로그아웃 항목이 없지만, 기존 로그아웃 기능을 지울 수 없어 계정 섹션에 둔다.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                children: [
                  Text('설정', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                  const SizedBox(height: 8),
                  Text('계정', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    title: '계정 정보',
                    subtitle: '이름, 이메일, 비밀번호',
                    onTap: () => context.push('/settings/account'),
                  ),
                  const SizedBox(height: 16),
                  Text('서비스 설정', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    title: '사용자 유형 변경',
                    subtitle: '현재: ${roleLabel(role)}',
                    onTap: () => context.push('/settings/role'),
                  ),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    title: '알림 설정',
                    subtitle: '수리 진행 알림 켜짐',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                  const SizedBox(height: 24),
                  Text('계정 관리', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                  const SizedBox(height: 8),
                  _SettingsRow(
                    title: '로그아웃',
                    subtitle: null,
                    titleColor: AppColors.accentRed,
                    onTap: () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ],
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

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.title, required this.subtitle, required this.onTap, this.titleColor});

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

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
                  Text(title, style: AppTextStyles.bodySemiBold14(color: titleColor ?? AppColors.gray8)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(subtitle!, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                  ],
                ],
              ),
            ),
            Text('>', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
          ],
        ),
      ),
    );
  }
}
