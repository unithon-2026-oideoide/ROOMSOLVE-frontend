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
