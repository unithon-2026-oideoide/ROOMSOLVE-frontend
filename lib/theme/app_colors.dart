import 'package:flutter/material.dart';

/// Color tokens extracted from the Figma file "ROOMSOLVE 와이어프레임"
/// (fileKey haIm2BdzxDs72DhVpDuNkg), sampled from the Figma variable
/// definitions bound to every top-level frame on Page 1.
///
/// Note: this file has no dedicated "DESIGN TOKEN" page — the palette below
/// was reconstructed by unioning the Figma variables actually applied
/// across all 28 screens. Gray4 and Gray9 never appear in any screen, so
/// the grayscale ramp below has a gap at those steps.
class AppColors {
  AppColors._();

  // Brand / Main ramp
  static const Color brandMain = Color(0xFF1D46F2); // "Main"
  static const Color brandLight = Color(0xFF374DF2); // "3"
  static const Color brandDark = Color(0xFF002BB2); // "2"
  static const Color brandDarkest = Color(0xFF001160); // "1"

  /// Alias for primary buttons — buttons in the wireframe consistently use
  /// [brandMain] as their fill color.
  static const Color buttonBlue = brandMain;

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Grayscale ramp (Gray4 / Gray9 not used anywhere in the file)
  static const Color gray1 = Color(0xFFF5F5F5);
  static const Color gray2 = Color(0xFFEDEDED);
  static const Color gray3 = Color(0xFFE0E0E0);
  static const Color gray5 = Color(0xFF9E9E9E);
  static const Color gray6 = Color(0xFF757575);
  static const Color gray7 = Color(0xFF616161);
  static const Color gray8 = Color(0xFF424242);

  // Accents
  static const Color accentRed = Color(0xFFFF383C);
  static const Color accentGreen = Color(0xFF34C759);
  static const Color accentYellow = Color(0xFFFFCC00);

  /// 카드 등 흰 배경 요소에 쓰는 공용 그림자. 예전엔 브랜드 블루가 10% 섞인
  /// rgba(29,70,242,0.10)이라 카드마다 옅은 파란 헤일로가 졌다 — 색을 뺀
  /// 중립(잉크색 기반) 톤으로 바꾸고, 촘촘한 레이어(경계) + 넓은 레이어(들뜬
  /// 느낌) 두 겹으로 구성했다. 아이콘/버튼 등 다른 곳의 색은 그대로다.
  static const List<BoxShadow> dropShadow = [
    BoxShadow(color: Color(0x0A14161F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F14161F), offset: Offset(0, 6), blurRadius: 18),
  ];
}
