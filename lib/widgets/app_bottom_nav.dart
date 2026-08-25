import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

// Figma에서 내보낸 원본 아이콘. 셋 다 채우기 없이 선(stroke)으로만 그려져
// 있어서, 색은 SvgPicture의 colorFilter로 상태(선택/비선택)에 맞게 입힌다 —
// SVG 파일 자체에 박힌 색(#002BB2)은 무시된다.
const _homeIcon = 'assets/icons/nav_home.svg';
const _reportsIcon = 'assets/icons/nav_reports.svg';
const _settingsIcon = 'assets/icons/nav_settings.svg';

enum AppBottomNavTab { home, reports, settings }

/// 화면 하단에 여백을 두고 떠 있는 캡슐형 내비게이션. 라벨 없이 아이콘 색과
/// 아이콘 아래 작은 점 인디케이터로 활성 탭을 나타낸다 — 예전의 "화면 폭 전체
/// + 진한 파란 헤일로 그림자" 바 대신, 요즘 앱들이 쓰는 좀 더 가벼운 형태다.
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 10),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Color(0x1F14161F), offset: Offset(0, 6), blurRadius: 24),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavTab(
              iconAsset: _homeIcon,
              active: current == AppBottomNavTab.home,
              onTap: () => context.go(homePath),
            ),
            _NavTab(
              iconAsset: _reportsIcon,
              active: current == AppBottomNavTab.reports,
              // 홈 탭과 마찬가지로 go()를 쓴다. push()였을 때는 이미 이 탭에 있는
              // 상태에서 같은 아이콘을 다시 누를 때마다 같은 화면이 스택에 계속
              // 쌓여서, 뒤로가기를 여러 번 눌러야 빠져나올 수 있었다.
              onTap: () => context.go(reportsPath),
            ),
            _NavTab(
              iconAsset: _settingsIcon,
              active: current == AppBottomNavTab.settings,
              onTap: () => context.go('/settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.iconAsset, required this.active, required this.onTap});

  final String iconAsset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.brandMain : AppColors.gray5;
    return InkResponse(
      onTap: onTap,
      radius: 28,
      containedInkWell: true,
      highlightShape: BoxShape.circle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 5),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.brandMain : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
