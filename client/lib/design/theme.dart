import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'spacing.dart';
import 'typography.dart';

class TwendeTheme {
  TwendeTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: TwendeColors.accent,
        onPrimary: TwendeColors.textInverse,
        secondary: TwendeColors.primary,
        onSecondary: TwendeColors.textInverse,
        surface: TwendeColors.surface,
        onSurface: TwendeColors.textPrimary,
        surfaceContainerHighest: TwendeColors.surfaceMuted,
        outline: TwendeColors.border,
        error: TwendeColors.danger,
      ),
      scaffoldBackgroundColor: TwendeColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: TwendeColors.background,
        foregroundColor: TwendeColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: TwendeColors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: TwendeColors.accent.withValues(alpha: 0.14),
        labelTextStyle: WidgetStatePropertyAll(TwendeTypography.caption),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? TwendeColors.accent
                : TwendeColors.textTertiary,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TwendeTypography.h1,
        displayMedium: TwendeTypography.h2,
        displaySmall: TwendeTypography.h3,
        headlineLarge: TwendeTypography.h1,
        headlineMedium: TwendeTypography.h2,
        headlineSmall: TwendeTypography.h3,
        titleLarge: TwendeTypography.title,
        titleMedium: TwendeTypography.title,
        bodyLarge: TwendeTypography.bodyLarge,
        bodyMedium: TwendeTypography.body,
        bodySmall: TwendeTypography.caption,
        labelLarge: TwendeTypography.button,
        labelMedium: TwendeTypography.label,
        labelSmall: TwendeTypography.caption,
      ),
      iconTheme: const IconThemeData(color: TwendeColors.textPrimary, size: 22),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TwendeColors.accent,
          foregroundColor: TwendeColors.textInverse,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TwendeSpacing.xl,
            vertical: TwendeSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TwendeSpacing.radiusPill),
          ),
          textStyle: TwendeTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TwendeColors.primary,
          side: const BorderSide(color: TwendeColors.border, width: 1.2),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(
            horizontal: TwendeSpacing.xl,
            vertical: TwendeSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TwendeSpacing.radiusPill),
          ),
          textStyle: TwendeTypography.button.copyWith(
            color: TwendeColors.accent,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TwendeColors.primary,
          textStyle: TwendeTypography.button.copyWith(
            color: TwendeColors.primary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TwendeColors.surfaceSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TwendeSpacing.lg,
          vertical: TwendeSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
          borderSide: const BorderSide(color: TwendeColors.primary, width: 1.5),
        ),
        hintStyle: TwendeTypography.body.copyWith(
          color: TwendeColors.textTertiary,
        ),
        prefixIconColor: TwendeColors.textTertiary,
        suffixIconColor: TwendeColors.textTertiary,
      ),
      dividerTheme: const DividerThemeData(
        color: TwendeColors.borderSubtle,
        space: 1,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TwendeColors.surface,
        selectedItemColor: TwendeColors.primary,
        unselectedItemColor: TwendeColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TwendeTypography.caption,
        unselectedLabelStyle: TwendeTypography.caption,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TwendeColors.surfaceMuted,
        labelStyle: TwendeTypography.label,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusPill),
        ),
      ),
      cardTheme: CardThemeData(
        color: TwendeColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
