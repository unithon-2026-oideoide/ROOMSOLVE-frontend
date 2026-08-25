import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

enum AppBottomNavTab { home, reports, settings }

/// Shared bottom navigation bar (home / reports / settings) matching the
/// Figma wireframe's rounded top-corner white bar with drop shadow.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    this.homePath = '/tenant',
    this.reportsPath = '/tenant/reports',
  });

  final AppBottomNavTab current;
  final String homePath;
  final String reportsPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: AppColors.dropShadowColor, offset: Offset(0, -4), blurRadius: 20),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(
              Icons.home_rounded,
              color: current == AppBottomNavTab.home ? AppColors.brandMain : AppColors.gray5,
              size: 30,
            ),
            onPressed: () => context.go(homePath),
          ),
          IconButton(
            icon: Icon(
              Icons.assignment_rounded,
              color: current == AppBottomNavTab.reports ? AppColors.brandMain : AppColors.gray5,
              size: 30,
            ),
            // 홈 탭과 마찬가지로 go()를 쓴다. push()였을 때는 이미 이 탭에 있는
            // 상태에서 같은 아이콘을 다시 누를 때마다 같은 화면이 스택에 계속
            // 쌓여서, 뒤로가기를 여러 번 눌러야 빠져나올 수 있었다.
            onPressed: () => context.go(reportsPath),
          ),
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: current == AppBottomNavTab.settings ? AppColors.brandMain : AppColors.gray5,
              size: 30,
            ),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }
}
