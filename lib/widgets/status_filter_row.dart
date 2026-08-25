import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 상태 필터를 고르는 가로 스크롤 알약(chip) 줄. 신고/요청 목록 화면들이
/// 쓰던 네이티브 DropdownButton을 대체한다 — 시스템 팝업 메뉴가 카드 위주의
/// 나머지 화면과 이질감이 커서, 다른 곳처럼 눈에 보이는 알약 형태로 통일했다.
class StatusFilterRow extends StatelessWidget {
  const StatusFilterRow({super.key, required this.filters, required this.selected, required this.onSelected});

  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = f == selected;
          return GestureDetector(
            onTap: () => onSelected(f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.brandMain : AppColors.gray1,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                f,
                style: AppTextStyles.bodyRegular14(color: isSelected ? AppColors.white : AppColors.gray7),
              ),
            ),
          );
        },
      ),
    );
  }
}
