import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api_client.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/app_bottom_nav.dart';

const _whenOptions = ['오늘', '어제', '2~3일 전', '일주일 이상 전', '한 달 이상 전'];
const _frequencyOptions = ['처음 발생', '가끔 발생', '자주 발생', '지속적으로 발생'];

/// 2단계: 추가 정보 입력. 실제 사진 업로드 + AI 분석(ReportService.analyzeReport)
/// 호출은 원래 report_create_screen에 있던 로직을 그대로 이 화면으로 옮겨와 수행한다.
class ReportAdditionalInfoScreen extends StatefulWidget {
  const ReportAdditionalInfoScreen({super.key, required this.description, required this.photos});

  final String description;
  final List<File> photos;

  @override
  State<ReportAdditionalInfoScreen> createState() => _ReportAdditionalInfoScreenState();
}

class _ReportAdditionalInfoScreenState extends State<ReportAdditionalInfoScreen> {
  String? _when;
  String? _frequency;
  final _areaController = TextEditingController();
  bool _hasPriorRepair = true;
  File? _extraPhoto;
  final _picker = ImagePicker();

  bool _isSubmitting = false;
  String? _errorMessage;
  String _statusMessage = '';

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickExtraPhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _extraPhoto = File(picked.path));
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = '사진 업로드 중...';
    });

    final allPhotos = [...widget.photos, ?_extraPhoto];
    final detailLines = [
      widget.description,
      '',
      if (_when != null) '[문제 발생 시점] $_when',
      if (_frequency != null) '[발생 빈도] $_frequency',
      if (_areaController.text.trim().isNotEmpty) '[피해 범위] ${_areaController.text.trim()}',
      '[이전 수리 이력] ${_hasPriorRepair ? '있음' : '없음'}',
    ];

    try {
      final Report result = await ReportService.instance.analyzeReport(
        description: detailLines.join('\n'),
        photos: allPhotos,
        onUploadProgress: (completed, total) {
          if (!mounted) return;
          setState(() {
            _statusMessage = completed >= total ? 'AI 분석 중...' : '사진 업로드 중... ($completed/$total)';
          });
        },
      );
      if (mounted) context.push('/tenant/reports/result', extra: result);
    } on PhotoUploadException catch (e) {
      setState(() => _errorMessage = '사진 업로드에 실패했습니다: ${e.message}');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = '요청 처리 중 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _statusMessage = '';
        });
      }
    }
  }

  BoxDecoration get _fieldBoxDecoration => BoxDecoration(
        color: AppColors.gray2,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.dropShadow,
      );

  Widget _fieldCard({required String label, required Widget field}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppColors.dropShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodyRegular16(color: const Color(0xFF212121))),
          const SizedBox(height: 8),
          field,
        ],
      ),
    );
  }

  Widget _dropdown(String hint, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: _fieldBoxDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: AppTextStyles.bodyRegular14(color: const Color(0xFF8C8C8C))),
          icon: const Icon(Icons.expand_more, size: 16, color: Color(0xFF212121)),
          items: [for (final o in options) DropdownMenuItem(value: o, child: Text(o))],
          onChanged: onChanged,
          style: AppTextStyles.bodyRegular14(color: const Color(0xFF212121)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    Text('추가 정보 입력', style: AppTextStyles.subtitleBold22(color: AppColors.black)),
                    const SizedBox(height: 20),
                    Text(
                      'AI가 문제 상황을 더 정확히 파악할 수 있도록 아래 항목을 답해 주세요.',
                      style: AppTextStyles.bodyRegular16(color: AppColors.gray8),
                    ),
                    const SizedBox(height: 20),
                    _fieldCard(
                      label: '문제 발생 시점',
                      field: _dropdown(
                        '언제부터 발생했나요? (예: 3일 전, 지난주)',
                        _when,
                        _whenOptions,
                        (v) => setState(() => _when = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _fieldCard(
                      label: '발생 빈도',
                      field: _dropdown(
                        '얼마나 자주 발생하나요?',
                        _frequency,
                        _frequencyOptions,
                        (v) => setState(() => _frequency = v),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _fieldCard(
                      label: '피해 범위',
                      field: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: _fieldBoxDecoration,
                        child: TextField(
                          controller: _areaController,
                          style: AppTextStyles.bodyRegular14(color: const Color(0xFF212121)),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: '누수, 냄새 등 영향을 받는 공간을 입력해 주세요',
                            hintStyle: AppTextStyles.bodyRegular14(color: const Color(0xFF8C8C8C)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('이전 수리 이력', style: AppTextStyles.bodyRegular16(color: const Color(0xFF212121))),
                          const SizedBox(height: 8),
                          RadioGroup<bool>(
                            groupValue: _hasPriorRepair,
                            onChanged: (v) => setState(() => _hasPriorRepair = v!),
                            child: Row(
                              children: [
                                Radio<bool>(value: true, activeColor: AppColors.black),
                                Text('있음', style: AppTextStyles.bodyRegular14(color: const Color(0xFF212121))),
                                const SizedBox(width: 24),
                                Radio<bool>(value: false, activeColor: AppColors.black),
                                Text('없음', style: AppTextStyles.bodyRegular14(color: const Color(0xFF212121))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppColors.dropShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('보완 사진 첨부 (선택)', style: AppTextStyles.bodyRegular14(color: const Color(0xFF212121))),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickExtraPhoto,
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: _fieldBoxDecoration,
                              child: _extraPhoto == null
                                  ? Icon(Icons.add_a_photo_outlined, color: AppColors.gray6)
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(_extraPhoto!, fit: BoxFit.cover),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                      const SizedBox(height: 12),
                    ],
                    if (_isSubmitting && _statusMessage.isNotEmpty) ...[
                      Text(
                        _statusMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyRegular14(color: AppColors.gray7),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 39,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
                              )
                            : Text('다음 단계로', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const AppBottomNav(current: AppBottomNavTab.reports),
          ],
        ),
      ),
    );
  }
}
