import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// 뒤로가기 버튼 + 제목 한 줄. 하단 내비게이션의 탭 화면이 아니라 push로
/// 들어오는 화면들이 공통으로 쓴다 — AppTopBar를 없앤 뒤로는 이 헤더가 각
/// 화면에서 이전 화면으로 돌아갈 수 있다는 걸 보여주는 유일한 표시다.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.trailing, this.onBack});

  final String title;

  /// 제목 오른쪽에 붙는 부가 요소(상태 배지 등). 기존에 제목과 같은 줄에
  /// 배지를 두던 화면들이 이걸로 그 배지를 그대로 옮겨 쓴다.
  final Widget? trailing;

  /// 기본은 context.pop() — 스택에 쌓인 이전 화면으로 돌아간다.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: onBack ?? () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.subtitleBold22(color: AppColors.black),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}
