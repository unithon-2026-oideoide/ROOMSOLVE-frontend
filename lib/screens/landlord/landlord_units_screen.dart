import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../services/landlord_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_top_bar.dart';

/// "임대인 - 호실 관리 화면"
class LandlordUnitsScreen extends StatefulWidget {
  const LandlordUnitsScreen({super.key});

  @override
  State<LandlordUnitsScreen> createState() => _LandlordUnitsScreenState();
}

class _LandlordUnitsScreenState extends State<LandlordUnitsScreen> {
  List<Map<String, dynamic>>? _units;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await LandlordService.instance.getProperties();
      setState(() {
        _units = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '호실 정보를 불러오지 못했습니다: $e';
        _isLoading = false;
      });
    }
  }

  bool _isVacant(Map<String, dynamic> u) {
    final status = u['status']?.toString().toLowerCase();
    return status == 'vacant' || status == 'empty' || status == '공실';
  }

  @override
  Widget build(BuildContext context) {
    final units = _units ?? const [];

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              Center(child: Text(_errorMessage!, style: AppTextStyles.bodyRegular14(color: AppColors.accentRed))),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            children: [
                              Text('호실 관리', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                              const SizedBox(height: 4),
                              Text('관리 중인 호실 ${units.length}개', style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                              const SizedBox(height: 12),
                              for (final u in units) ...[
                                _UnitCard(unit: u, isVacant: _isVacant(u)),
                                const SizedBox(height: 8),
                              ],
                              if (units.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text('등록된 호실이 없습니다.', style: AppTextStyles.bodyRegular14(color: AppColors.gray6)),
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

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.unit, required this.isVacant});
  final Map<String, dynamic> unit;
  final bool isVacant;

  @override
  Widget build(BuildContext context) {
    final name = unit['unit']?.toString() ?? unit['name']?.toString() ?? '호실';
    final tenant = unit['tenantName']?.toString() ?? (isVacant ? '공실' : '입주자 정보 없음');
    final statusLabel = isVacant ? '공실' : '입주 중';
    final detail = unit['contractEnd']?.toString() != null
        ? '계약만료 ${unit['contractEnd']}'
        : (isVacant ? '임대 안내 게시 중' : '계약 정보 없음');
    final requestSummary = unit['openRequestSummary']?.toString() ?? '없음';

    return Container(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.bodySemiBold14(color: AppColors.gray8)),
                    const SizedBox(height: 8),
                    Text(tenant, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusLabel, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                    const SizedBox(height: 8),
                    Text(detail, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('수리 요청', style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
              const Spacer(),
              Text(requestSummary, style: AppTextStyles.bodyRegular12(color: AppColors.gray6)),
            ],
          ),
        ],
      ),
    );
  }
}
