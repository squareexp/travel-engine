import 'package:flutter/material.dart';

/// Bold UI palette. Clean white, near-black hero blocks, muted grey chips.
/// No borders, no shadows. Contrast comes from fill, not strokes.
class TwendeColors {
  TwendeColors._();

  // Near-black, used as the bold accent / CTAs / hero cards.
  static const Color primary = Color(0xFF1A1F2E);
  static const Color primaryLight = Color(0xFF2A2F3E);
  static const Color primaryDark = Color(0xFF0A1320);
  static const Color accent = Color(0xFF1A1F2E);

  // Surfaces.
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEFEFF1);
  static const Color surfaceSubtle = Color(0xFFF7F7F8);

  // Text.
  static const Color textPrimary = Color(0xFF0A1320);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFFA0A6B0);
  static const Color textInverse = Color(0xFFFFFFFF);

  // Legacy alias — kept as muted so anything still referencing the old token
  // resolves to the new contrast surface instead of drawing a hairline.
  static const Color border = Color(0xFFEFEFF1);
  static const Color borderSubtle = Color(0xFFEFEFF1);

  // Status — badges only.
  static const Color success = Color(0xFF0F8A4F);
  static const Color successBg = Color(0xFFE5F4EC);
  static const Color warning = Color(0xFFB46A0F);
  static const Color warningBg = Color(0xFFFAF0DC);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFCE8E8);

  static const Color star = Color(0xFFD78B15);
  static const Color shadow = Color(0x00000000);
}
