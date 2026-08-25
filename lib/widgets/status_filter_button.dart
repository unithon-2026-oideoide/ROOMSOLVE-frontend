import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 상태 필터를 고르는 트리거 버튼 + 바텀시트.
///
/// 예전엔 가로로 쭉 늘어선 알약(칩) 줄이었는데 "버튼처럼 보여서 필터라는
/// 느낌이 안 들고, 옵션이 많으면 옆으로 잘려서 스크롤해야 한다"는 피드백을
/// 받았다. 지금은 현재 선택된 상태 하나만 버튼으로 보여주고, 누르면 시트에서
/// 전체 옵션(+ 옵션별 개수)을 고르는 방식이다 — report_create_screen.dart의
/// 사진 추가 시트와 같은 톤(둥근 상단 모서리, 드래그 핸들, 카드형 옵션).
class StatusFilterButton extends StatelessWidget {
  const StatusFilterButton({
    super.key,
    required this.title,
    required this.filters,
    required this.selected,
    required this.onSelected,
    this.counts,
    this.colorOf,
  });

  /// 버튼/시트 제목에 쓰는 항목 이름(예: "상태").
  final String title;
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  /// 항목별 개수. 있으면 버튼과 시트 옵션 옆에 "(3)"처럼 표시한다.
  final Map<String, int>? counts;

  /// 항목별 상태 색. 있으면 버튼과 시트 옵션 앞에 작은 점으로 보여준다.
  final Color Function(String label)? colorOf;

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.gray3, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 20),
              Text('$title 필터', style: AppTextStyles.subtitleBold18(color: AppColors.black)),
              const SizedBox(height: 16),
              for (int i = 0; i < filters.length; i++) ...[
                _StatusOptionTile(
                  label: filters[i],
                  count: counts?[filters[i]],
                  color: colorOf?.call(filters[i]),
                  selected: filters[i] == selected,
                  onTap: () => Navigator.pop(context, filters[i]),
                ),
                if (i != filters.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final count = counts?[selected];
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppColors.gray1, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (colorOf != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: colorOf!(selected))),
              const SizedBox(width: 8),
            ],
            Text(
              count != null ? '$title: $selected ($count)' : '$title: $selected',
              style: AppTextStyles.bodySemiBold14(color: AppColors.gray8),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 18, color: AppColors.gray6),
          ],
        ),
      ),
    );
  }
}

class _StatusOptionTile extends StatelessWidget {
  const _StatusOptionTile({required this.label, required this.selected, required this.onTap, this.count, this.color});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandMain.withValues(alpha: 0.08) : AppColors.gray1,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              if (color != null) ...[
                Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  count != null ? '$label ($count)' : label,
                  style: AppTextStyles.bodySemiBold16(color: AppColors.gray8),
                ),
              ),
              if (selected) Icon(Icons.check_rounded, size: 20, color: AppColors.brandMain),
            ],
          ),
        ),
      ),
    );
  }
}
