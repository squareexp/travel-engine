import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

/// Photo-led hero card used on Home as "Featured".
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.cta = 'Explore',
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageUrl;
  final String cta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Semantics(
        button: onTap != null,
        label: '$title. $subtitle',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      Container(color: TwendeColors.surfaceMuted),
                  errorWidget: (_, __, ___) => Container(
                    color: TwendeColors.surfaceMuted,
                    child: const Icon(
                      IconsaxPlusLinear.gallery_slash,
                      color: TwendeColors.textTertiary,
                      size: 32,
                    ),
                  ),
                ),
                Positioned(
                  top: TwendeSpacing.md,
                  left: TwendeSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: TwendeColors.textInverse,
                      borderRadius: BorderRadius.circular(
                        TwendeSpacing.radiusPill,
                      ),
                    ),
                    child: Text(
                      'Featured',
                      style: TwendeTypography.caption.copyWith(
                        color: TwendeColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                // A restrained overlay keeps text readable over any source photo.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(TwendeSpacing.lg),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0x00000000), Color(0xE6062634)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TwendeTypography.h2.copyWith(
                            color: TwendeColors.textInverse,
                          ),
                        ),
                        const SizedBox(height: TwendeSpacing.xs),
                        Text(
                          subtitle,
                          style: TwendeTypography.body.copyWith(
                            color: TwendeColors.textInverse.withValues(
                              alpha: 0.85,
                            ),
                          ),
                        ),
                        const SizedBox(height: TwendeSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TwendeSpacing.lg,
                            vertical: TwendeSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: TwendeColors.textInverse,
                            borderRadius: BorderRadius.circular(
                              TwendeSpacing.radiusPill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                cta,
                                style: TwendeTypography.button.copyWith(
                                  color: TwendeColors.primary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                IconsaxPlusLinear.arrow_right_3,
                                color: TwendeColors.primary,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
