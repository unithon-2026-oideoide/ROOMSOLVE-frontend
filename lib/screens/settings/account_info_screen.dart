import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "계정 정보 화면". 서비스 가입일 필드는 백엔드 AppUser 모델에 없어
/// 디자인의 예시 문구를 그대로 표시한다.
class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

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
                    Text('계정 정보', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 16),
                    _Field(label: '사용자 유형', value: roleLabel(auth.role)),
                    const SizedBox(height: 20),
                    _Field(label: '이메일', value: user?.email.isNotEmpty == true ? user!.email : 'user@example.com'),
                    const SizedBox(height: 20),
                    _Field(label: '전화번호', value: user?.phone ?? '등록된 전화번호가 없습니다'),
                    const SizedBox(height: 20),
                    _Field(
                      label: '서비스 가입일',
                      value: user?.createdAt != null
                          ? '${user!.createdAt!.year}년 ${user.createdAt!.month}월 ${user.createdAt!.day}일'
                          : '정보 없음',
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.gray2,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: AppColors.dropShadow,
                        ),
                        alignment: Alignment.center,
                        child: Text('설정으로 돌아가기', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
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

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: AppColors.dropShadow,
          ),
          child: Text(value, style: AppTextStyles.bodyRegular16(color: AppColors.gray8)),
        ),
      ],
    );
  }
}
