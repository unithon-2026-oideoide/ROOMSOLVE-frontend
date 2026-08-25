import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shared "ROOMSOLVE" header bar used at the top of most screens in the
/// Figma wireframe (white background, drop shadow, centered wordmark).
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: AppColors.dropShadow,
      ),
      child: Text('ROOMSOLVE', style: AppTextStyles.subtitleBold22(color: AppColors.brandMain)),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
