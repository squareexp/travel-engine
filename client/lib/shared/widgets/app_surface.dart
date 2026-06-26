import 'package:flutter/material.dart';

import '../../design/colors.dart';
import '../../design/spacing.dart';

/// A single surface recipe for cards, itinerary rows, and grouped settings.
/// Inner media should use [innerRadius] to retain concentric corner geometry.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(TwendeSpacing.lg),
    this.radius = TwendeSpacing.radiusLg,
    this.emphasis = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool emphasis;
  final VoidCallback? onTap;

  static const double innerRadius = TwendeSpacing.radiusMd;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: emphasis
            ? Colors.white.withValues(alpha: .16)
            : TwendeColors.borderSubtle,
      ),
    );
    return Material(
      color: emphasis ? TwendeColors.primary : TwendeColors.surface,
      elevation: 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
