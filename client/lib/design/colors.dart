import 'package:flutter/material.dart';

/// Twende brand palette — bold, vibrant, NO gradients.
/// Matches the mockups in client/ui/.
class TwendeColors {
  TwendeColors._();

  // Ocean is the navigational anchor; teal is reserved for clear actions.
  static const Color primary = Color(0xFF0B3B53);
  static const Color primaryLight = Color(0xFF17607A);
  static const Color primaryDark = Color(0xFF062634);
  static const Color accent = Color(0xFF0A8F8B);

  // Surface — warm off-white.
  static const Color background = Color(0xFFFCFAF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F4F2);
  static const Color surfaceSubtle = Color(0xFFF7F8F5);

  // Text scale.
  static const Color textPrimary = Color(0xFF0A1A2E);
  static const Color textSecondary = Color(0xFF4A5566);
  static const Color textTertiary = Color(0xFF8A94A6);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Borders / dividers.
  static const Color border = Color(0xFFE7E3DB);
  static const Color borderSubtle = Color(0xFFEFEBE2);

  // Accent — only used for state badges, never as backgrounds.
  static const Color success = Color(0xFF1B7F4A);
  static const Color successBg = Color(0xFFE3F3EA);
  static const Color warning = Color(0xFFC97A1B);
  static const Color warningBg = Color(0xFFFCEFD9);
  static const Color danger = Color(0xFFB42318);
  static const Color dangerBg = Color(0xFFFBE8E6);

  // Star/rating.
  static const Color star = Color(0xFFD78B15);

  // Shadow tone.
  static const Color shadow = Color(0x1A0B2447);
}
