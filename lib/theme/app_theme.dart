import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

/// App-wide [ThemeData] built from the Figma design tokens in [AppColors]
/// and [AppTextStyles].
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandMain,
        brightness: Brightness.light,
        primary: AppColors.brandMain,
        onPrimary: AppColors.white,
        secondary: AppColors.brandLight,
        error: AppColors.accentRed,
        surface: AppColors.white,
        onSurface: AppColors.black,
      ),
      // 어느 플랫폼에서 빌드하든 iOS 스타일 "왼쪽 끝에서 오른쪽으로 스와이프하면
      // 뒤로가기" 제스처를 쓰게 한다. Flutter 기본값은 iOS/macOS만 이 제스처가
      // 있는 CupertinoPageTransitionsBuilder를 쓰고 Android 등은 스와이프가 없는
      // ZoomPageTransitionsBuilder를 쓴다 — 요즘 앱들이 흔히 그러듯, 플랫폼과
      // 무관하게 하나로 통일했다. go_router의 push로 들어가는 화면이면(홈→상세,
      // 목록→상세, 설정→하위 화면 등 진입 경로와 무관하게) 전부 적용된다.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.subtitleBold18(),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.titleBold30(),
        headlineMedium: AppTextStyles.subtitleBold22(),
        headlineSmall: AppTextStyles.subtitleBold18(),
        titleMedium: AppTextStyles.subtitleSemiBold16(),
        bodyLarge: AppTextStyles.bodyRegular16(),
        bodyMedium: AppTextStyles.bodyRegular14(),
        bodySmall: AppTextStyles.bodyRegular12(),
        labelLarge: AppTextStyles.buttonRegular14(),
        labelSmall: AppTextStyles.captionLight12(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.gray3,
          textStyle: AppTextStyles.buttonRegular14(),
          minimumSize: const Size.fromHeight(47),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.gray1,
        hintStyle: AppTextStyles.bodyRegular14(color: AppColors.gray5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      dividerColor: AppColors.gray2,
      cardColor: AppColors.white,
      fontFamily: AppTextStyles.bodyRegular14().fontFamily,
    );
  }
}
