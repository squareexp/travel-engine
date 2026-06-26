import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TwendeSpacing.md,
            vertical: TwendeSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? TwendeColors.primary : TwendeColors.surfaceMuted,
            borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected
                    ? TwendeColors.textInverse
                    : TwendeColors.textPrimary,
              ),
              const SizedBox(height: TwendeSpacing.xs),
              Text(
                label,
                style: TwendeTypography.caption.copyWith(
                  color: selected
                      ? TwendeColors.textInverse
                      : TwendeColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
