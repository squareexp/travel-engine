import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

enum SheetKind { info, success, warning, error }

/// One-call helper for any "we need to tell the user something" moment.
/// Always renders as a bottom sheet so the underlying screen never deforms.
class AppSheet {
  AppSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    SheetKind kind = SheetKind.info,
    String primaryLabel = 'OK',
    VoidCallback? onPrimary,
    String? secondaryLabel,
    VoidCallback? onSecondary,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SheetBody(
        title: title,
        message: message,
        kind: kind,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
        onPrimary: onPrimary,
        onSecondary: onSecondary,
      ),
    );
  }

  /// Convenience for error reporting; just call AppSheet.error(ctx, e).
  static Future<void> error(
    BuildContext context,
    Object error, {
    String title = 'Something went wrong',
  }) {
    return show(
      context,
      title: title,
      message: error.toString(),
      kind: SheetKind.error,
    );
  }

  /// Light non-blocking toast at the bottom of the screen.
  static void toast(
    BuildContext context,
    String message, {
    SheetKind kind = SheetKind.info,
  }) {
    final color = switch (kind) {
      SheetKind.success => TwendeColors.success,
      SheetKind.warning => TwendeColors.warning,
      SheetKind.error => TwendeColors.danger,
      _ => TwendeColors.primary,
    };
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(TwendeSpacing.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
        ),
        content: Text(
          message,
          style: TwendeTypography.body.copyWith(
            color: TwendeColors.textInverse,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.title,
    required this.message,
    required this.kind,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  final String title;
  final String? message;
  final SheetKind kind;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: TwendeColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TwendeSpacing.radiusXl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          TwendeSpacing.xl,
          TwendeSpacing.md,
          TwendeSpacing.xl,
          TwendeSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: TwendeSpacing.lg),
                decoration: BoxDecoration(
                  color: TwendeColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Glyph(kind: kind),
                const SizedBox(width: TwendeSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TwendeTypography.h3),
                      if (message != null) ...[
                        const SizedBox(height: TwendeSpacing.xs),
                        Text(
                          message!,
                          style: TwendeTypography.body,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: TwendeSpacing.xl),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onPrimary?.call();
              },
              child: Text(primaryLabel),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: TwendeSpacing.sm),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSecondary?.call();
                },
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Glyph extends StatelessWidget {
  const _Glyph({required this.kind});
  final SheetKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, color, bg) = switch (kind) {
      SheetKind.success => (
        IconsaxPlusBold.tick_circle,
        TwendeColors.success,
        TwendeColors.successBg,
      ),
      SheetKind.warning => (
        IconsaxPlusBold.warning_2,
        TwendeColors.warning,
        TwendeColors.warningBg,
      ),
      SheetKind.error => (
        IconsaxPlusBold.close_circle,
        TwendeColors.danger,
        TwendeColors.dangerBg,
      ),
      _ => (
        IconsaxPlusBold.info_circle,
        TwendeColors.primary,
        TwendeColors.surfaceMuted,
      ),
    };
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
