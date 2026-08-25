import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/role_routes.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';

/// "알림 설정 화면". 알림 설정 전용 백엔드 API가 없어 로컬 상태만 다룬다.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _statusChange = true;
  bool _technicianEta = true;
  bool _completion = true;
  bool _reservationConfirm = true;
  bool _visitReminder = true;
  bool _approvalRequest = true;
  bool _estimatedCost = true;
  bool _push = true;
  bool _sms = false;
  bool _email = false;

  Widget _toggleRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
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
                Text(title, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                const SizedBox(height: 8),
                Text(subtitle, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.white, activeTrackColor: AppColors.brandDark),
        ],
      ),
    );
  }

  Widget _checkboxRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? AppColors.brandDark : AppColors.white,
                border: value ? null : Border.all(color: const Color(0xFFB3B3B3)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('알림 설정', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 12),
                    Text('수리 진행 알림', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    const SizedBox(height: 12),
                    _toggleRow('상태 변경 알림', '신고 승인, 시공 예약 등 상태 변경 시 알림', _statusChange, (v) => setState(() => _statusChange = v)),
                    const SizedBox(height: 12),
                    _toggleRow('기술자 도착 예상', '기술자 도착 예상 30분 전 알림', _technicianEta, (v) => setState(() => _technicianEta = v)),
                    const SizedBox(height: 12),
                    _toggleRow('완료 알림', '수리 완료 시 알림', _completion, (v) => setState(() => _completion = v)),
                    const SizedBox(height: 20),
                    Text('일정 알림', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    const SizedBox(height: 12),
                    _toggleRow('예약 확인', '예약한 시간 24시간 전 알림', _reservationConfirm, (v) => setState(() => _reservationConfirm = v)),
                    const SizedBox(height: 12),
                    _toggleRow('방문 알림', '예약 시간 2시간 전 알림', _visitReminder, (v) => setState(() => _visitReminder = v)),
                    const SizedBox(height: 20),
                    Text('승인 및 결정 알림', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    const SizedBox(height: 12),
                    _toggleRow('승인 요청 알림', '고비용 수리나 추가 작업 승인 필요 시 알림', _approvalRequest, (v) => setState(() => _approvalRequest = v)),
                    const SizedBox(height: 12),
                    _toggleRow('추정 비용 알림', '추정 비용이 통보될 때 알림', _estimatedCost, (v) => setState(() => _estimatedCost = v)),
                    const SizedBox(height: 20),
                    Text('알림 수신 채널', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                    const SizedBox(height: 12),
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
                          Text('수신 방식', style: AppTextStyles.bodyRegular14(color: AppColors.gray8)),
                          const SizedBox(height: 12),
                          _checkboxRow('푸시 알림', _push, (v) => setState(() => _push = v)),
                          _checkboxRow('문자 메시지', _sms, (v) => setState(() => _sms = v)),
                          _checkboxRow('이메일', _email, (v) => setState(() => _email = v)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFBFBFBF)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('취소', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('알림 설정이 저장되었습니다.')),
                                );
                                context.pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.brandLight,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              child: Text('저장', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                            ),
                          ),
                        ),
                      ],
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
