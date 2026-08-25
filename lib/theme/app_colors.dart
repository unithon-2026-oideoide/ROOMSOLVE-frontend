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

  /// "Drop Shadow" effect token: rgba(29,70,242,0.10), offset (4,4), radius 20
  static const Color dropShadowColor = Color(0x1A1D46F2);
  static const List<BoxShadow> dropShadow = [
    BoxShadow(
      color: dropShadowColor,
      offset: Offset(4, 4),
      blurRadius: 20,
    ),
  ];
}
