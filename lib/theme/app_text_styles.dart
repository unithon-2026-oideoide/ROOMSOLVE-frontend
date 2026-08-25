import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography ramp extracted from Figma variable definitions across all
/// screens in "ROOMSOLVE 와이어프레임".
///
/// Figma font family: "Pretendard". Pretendard is not published on Google
/// Fonts (google_fonts package exposes only fonts.google.com's catalog), so
/// this project substitutes Noto Sans KR — the closest Google Fonts
/// alternative with matching Korean glyph coverage. 원래 Pretendard, 대체
/// 폰트(Noto Sans KR) 사용 중.
///
/// Figma only defines the size/weight combinations found below — there is
/// no "Subtitle1/2/3" or "Body1/2/3" naming in the file itself. The primary
/// constants are named after Figma's own "`Category size, weight`"
/// tokens; numbered aliases (subtitle1/2/3, body1/2/3, caption1/2) are
/// provided afterwards, ordered largest → smallest, for convenience.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.black,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: 1.0,
      letterSpacing: 0,
      color: color,
    );
  }

  // Title/Mobile : 30, Bold
  static TextStyle titleBold30({Color color = AppColors.black}) =>
      _base(fontSize: 30, fontWeight: FontWeight.w700, color: color);

  // Subtitle/Mobile : 22, Bold
  static TextStyle subtitleBold22({Color color = AppColors.black}) =>
      _base(fontSize: 22, fontWeight: FontWeight.w700, color: color);

  // Subtitle/Mobile : 18, Bold
  static TextStyle subtitleBold18({Color color = AppColors.black}) =>
      _base(fontSize: 18, fontWeight: FontWeight.w700, color: color);

  // Subtitle/Mobile : 18, Regular
  static TextStyle subtitleRegular18({Color color = AppColors.black}) =>
      _base(fontSize: 18, fontWeight: FontWeight.w400, color: color);

  // Subtitle/Mobile : 16, SemiBold
  static TextStyle subtitleSemiBold16({Color color = AppColors.black}) =>
      _base(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  // Body/Mobile : 16, Regular
  static TextStyle bodyRegular16({Color color = AppColors.gray8}) =>
      _base(fontSize: 16, fontWeight: FontWeight.w400, color: color);

  // Body/Mobile : 16, SemiBold
  static TextStyle bodySemiBold16({Color color = AppColors.gray8}) =>
      _base(fontSize: 16, fontWeight: FontWeight.w600, color: color);

  // Body/Mobile : 14, Regular
  static TextStyle bodyRegular14({Color color = AppColors.gray8}) =>
      _base(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  // Body/Mobile : 14, SemiBold
  static TextStyle bodySemiBold14({Color color = AppColors.gray8}) =>
      _base(fontSize: 14, fontWeight: FontWeight.w600, color: color);

  // Body/Mobile : 12, Regular
  static TextStyle bodyRegular12({Color color = AppColors.gray6}) =>
      _base(fontSize: 12, fontWeight: FontWeight.w400, color: color);

  // Button/Mobile : 14, Regular
  static TextStyle buttonRegular14({Color color = AppColors.white}) =>
      _base(fontSize: 14, fontWeight: FontWeight.w400, color: color);

  // Caption/Mobile : 12, Light
  static TextStyle captionLight12({Color color = AppColors.gray6}) =>
      _base(fontSize: 12, fontWeight: FontWeight.w300, color: color);

  // Caption/Mobile : 10, Regular
  static TextStyle captionRegular10({Color color = AppColors.gray5}) =>
      _base(fontSize: 10, fontWeight: FontWeight.w400, color: color);

  // --- Numbered aliases (largest → smallest), for convenience ---
  static TextStyle title({Color color = AppColors.black}) => titleBold30(color: color);

  static TextStyle subtitle1({Color color = AppColors.black}) => subtitleBold22(color: color);
  static TextStyle subtitle2({Color color = AppColors.black}) => subtitleBold18(color: color);
  static TextStyle subtitle3({Color color = AppColors.black}) => subtitleSemiBold16(color: color);

  static TextStyle body1({Color color = AppColors.gray8}) => bodyRegular16(color: color);
  static TextStyle body2({Color color = AppColors.gray8}) => bodyRegular14(color: color);
  static TextStyle body3({Color color = AppColors.gray6}) => bodyRegular12(color: color);

  static TextStyle button1({Color color = AppColors.white}) => buttonRegular14(color: color);

  static TextStyle caption1({Color color = AppColors.gray6}) => captionLight12(color: color);
  static TextStyle caption2({Color color = AppColors.gray5}) => captionRegular10(color: color);
}
