import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography scale — serif brand wordmark, sans-serif body.
class TwendeTypography {
  TwendeTypography._();

  static const String brandFamily = 'Playfair Display';
  static const String bodyFamily = 'Inter';

  static const TextStyle wordmark = TextStyle(
    fontFamily: brandFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: TwendeColors.primary,
    height: 1.1,
    letterSpacing: -0.3,
  );

  static const TextStyle h1 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: TwendeColors.textPrimary,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: TwendeColors.textPrimary,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: TwendeColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: TwendeColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: TwendeColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: TwendeColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: TwendeColors.textTertiary,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: TwendeColors.textInverse,
    letterSpacing: 0.1,
  );

  static const TextStyle label = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: TwendeColors.textPrimary,
  );
}
