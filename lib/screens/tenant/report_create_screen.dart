import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/screen_header.dart';

/// 1단계: 문제 설명 + 사진 첨부. "다음 단계로"에서 실제 업로드/AI 분석은
/// 하지 않고, 입력값을 들고 2단계(추가 정보 입력 화면)로 넘어간다.
/// 실제 ReportService.analyzeReport 호출은 추가 정보 입력 화면에서 수행한다.
class ReportCreateScreen extends StatefulWidget {
  const ReportCreateScreen({super.key});

  @override
  State<ReportCreateScreen> createState() => _ReportCreateScreenState();
}

class _ReportCreateScreenState extends State<ReportCreateScreen> {
  final _descriptionController = TextEditingController();
  final List<File> _photos = [];
  final _picker = ImagePicker();
  String? _errorMessage;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null) {
      setState(() => _photos.add(File(picked.path)));
    }
  }

  Future<void> _showAddPhotoSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    if (_photos.isEmpty) {
      setState(() => _errorMessage = '사진을 최소 1장 첨부해주세요.');
      return;
    }
    context.push(
      '/tenant/reports/new/details',
      extra: {'description': _descriptionController.text.trim(), 'photos': _photos},
    );
  }

  // 사진 칸 한 변의 길이. 예전엔 Row 안에서 Expanded + AspectRatio(1)로
  // 그렸는데, 사진이 0~1장일 때 Expanded가 남는 가로 폭을 전부 차지해서
  // 정사각형이 화면 너비만큼 커지는 문제가 있었다. 고정 크기로 바꾸고
  // Wrap으로 배치하면 사진이 몇 장이든 같은 크기를 유지한다.
  static const double _tileSize = 84;

  Widget _photoTile(int index) {
    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(_photos[index], fit: BoxFit.cover),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => setState(() => _photos.removeAt(index)),
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addTile() {
    return SizedBox(
      width: _tileSize,
      height: _tileSize,
      child: GestureDetector(
        onTap: _showAddPhotoSheet,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.gray2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add, color: AppColors.gray6),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenHeader(title: '문제 신고'),
                    const SizedBox(height: 20),
                    Text(
                      '발생한 문제를 사진과 함께 설명해 주세요. 정확한 내용이 빠른 해결에 도움이 됩니다.',
                      style: AppTextStyles.bodyRegular16(color: AppColors.gray8),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      minLines: 3,
                      style: AppTextStyles.bodyRegular16(color: AppColors.black),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.gray1,
                        hintText: '어떤 문제가 발생했나요?',
                        hintStyle: AppTextStyles.bodyRegular16(color: AppColors.gray6),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('사진·영상 첨부', style: AppTextStyles.subtitleBold18(color: const Color(0xFF212121))),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (int i = 0; i < _photos.length; i++) _photoTile(i),
                        _addTile(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '사진이나 영상을 추가하면 문제 상황을 더 정확히 전달할 수 있습니다.',
                      style: AppTextStyles.captionLight12(color: const Color(0xFF212121)),
                    ),
                    const SizedBox(height: 20),
                    if (_errorMessage != null) ...[
                      Text(_errorMessage!, style: AppTextStyles.bodyRegular12(color: AppColors.accentRed)),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      height: 39,
                      child: ElevatedButton(
                        onPressed: _goNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                          elevation: 0,
                        ),
                        child: Text('다음 단계로', style: AppTextStyles.bodySemiBold16(color: AppColors.white)),
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
