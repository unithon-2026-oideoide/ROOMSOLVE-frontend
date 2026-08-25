import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/screen_header.dart';

/// "임대인 - 승인 거절 안내": request_detail_screen에서 거절 처리(approveRequest
/// (approve: false))가 성공한 뒤 보여주는 완료 화면.
class RequestRejectedScreen extends StatelessWidget {
  const RequestRejectedScreen({super.key, required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final reasonText = reason.trim().isEmpty ? '사유가 입력되지 않았습니다.' : reason.trim();

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
                    const ScreenHeader(title: '요청 거절 완료'),
                    const SizedBox(height: 12),
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
                          Text('상태', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                          const SizedBox(height: 8),
                          Text('거절됨', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('거절 사유', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(8)),
                      child: Text(reasonText, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    ),
                    const SizedBox(height: 24),
                    Text('세입자 안내 메시지', style: AppTextStyles.bodySemiBold16(color: AppColors.gray8)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 8)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('임대인으로부터 요청 거절 알림', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                          const SizedBox(height: 12),
                          Text('세입자님이 신고하신 내용이 거절 처리되었습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodyRegular14(color: AppColors.gray8),
                              children: [
                                TextSpan(text: '사유: ', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                                TextSpan(text: reasonText),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('문의 사항이 있으시면 아래 연락처로 문의해 주세요.', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          const SizedBox(height: 4),
                          Text('추가 문의는 임대인에게 직접 연락주시기 바랍니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => context.go('/landlord/requests'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: Text('요청 목록으로', style: AppTextStyles.bodyRegular14(color: AppColors.white)),
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
