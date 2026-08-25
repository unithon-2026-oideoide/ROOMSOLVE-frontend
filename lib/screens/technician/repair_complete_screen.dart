
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/api_client.dart';
import '../../models/technician_job.dart';
import '../../services/repair_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "수리 완료 확인 화면". "확인 및 전송"이 POST /api/repair/status로
/// {report_id: job.id, status: 'done'}을 기록한다.
///
/// 완료 사진 첨부는 팀 결정으로 뺐다.
class RepairCompleteScreen extends StatefulWidget {
  const RepairCompleteScreen({super.key, required this.job});

  final TechnicianJob job;

  @override
  State<RepairCompleteScreen> createState() => _RepairCompleteScreenState();
}

class _RepairCompleteScreenState extends State<RepairCompleteScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmAndSend() async {
    setState(() => _isSubmitting = true);
    try {
      await RepairService.instance.postStatus(reportId: widget.job.id, status: 'done');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('수리 완료 알림을 전송했습니다.')),
        );
        context.go('/technician/jobs');
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('전송 중 오류가 발생했습니다: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
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
                    Text('작업 완료 처리', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 4),
                    Text('신청번호 #${job.id}', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    const SizedBox(height: 20),
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
                          Row(
                            children: [
                              Expanded(child: Text('작업 상태', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8))),
                              Text('완료', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '처리일시: ${DateTime.now().toString().substring(0, 16)}',
                            style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('세입자 알림 내용', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
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
                          Text('작업이 완료되었습니다', style: AppTextStyles.bodyRegular16(color: AppColors.gray8)),
                          const SizedBox(height: 12),
                          Text(
                            '${job.tenantName.isNotEmpty ? '${job.tenantName}님의 ' : ''}${job.title} 작업을 완료했습니다.',
                            style: AppTextStyles.bodyRegular12(color: AppColors.gray6),
                          ),
                          const SizedBox(height: 4),
                          Text('세부 사항은 신고 내역에서 확인할 수 있습니다.', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('신고 접수 사진', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: (job.photoUrl != null && job.photoUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(job.photoUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
                            )
                          : Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(color: const Color(0xFFE5E5EB), borderRadius: BorderRadius.circular(8)),
                              child: const Center(child: Text('신고 사진 없음', style: TextStyle(color: AppColors.gray6))),
                            ),
                    ),
                    const SizedBox(height: 20),
                    Text('비용 현황', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
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
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('예정 비용', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8))),
                              Text(job.estimatedCost ?? '-', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: Text('실제 비용', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8))),
                              Text(job.actualCost ?? job.estimatedCost ?? '-', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _confirmAndSend,
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
                            : Text('확인 및 전송', style: AppTextStyles.bodySemiBold14(color: AppColors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () => context.go('/technician/jobs'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFBFBFBF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text('작업 목록으로', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports, homePath: '/technician', reportsPath: '/technician/jobs'),
          ],
        ),
      ),
    );
  }
}
