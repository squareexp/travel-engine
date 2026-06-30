import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/models.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({super.key, required this.listing, this.onTap});

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = _fallbackImage(listing.listingType);
    return Semantics(
      button: onTap != null,
      label: '${listing.title}, ${listing.formattedPrice}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
          child: Container(
            color: TwendeColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 11,
                  child: CachedNetworkImage(
                    imageUrl: listing.heroImageUrl ?? fallback,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: TwendeColors.surfaceMuted),
                    errorWidget: (_, _, _) => Container(
                      color: TwendeColors.surfaceMuted,
                      child: const Icon(
                        IconsaxPlusLinear.gallery_slash,
                        color: TwendeColors.textTertiary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(TwendeSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TwendeTypography.title,
                      ),
                      if (listing.destinationName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          listing.destinationName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TwendeTypography.caption,
                        ),
                      ],
                      const SizedBox(height: TwendeSpacing.sm),
                      Row(
                        children: [
                          Text(
                            listing.formattedPrice,
                            style: TwendeTypography.title.copyWith(
                              color: TwendeColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('/ person', style: TwendeTypography.caption),
                          const Spacer(),
                          if (listing.averageRating != null) ...[
                            const Icon(
                              IconsaxPlusBold.star_1,
                              color: TwendeColors.star,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              listing.averageRating!.toStringAsFixed(1),
                              style: TwendeTypography.caption.copyWith(
                                color: TwendeColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
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

String _fallbackImage(String type) {
  switch (type) {
    case 'safari':
      return 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800';
    case 'trip':
      return 'https://images.unsplash.com/photo-1591608971362-f08b2a75731a?w=800';
    case 'site':
      return 'https://images.unsplash.com/photo-1580973193083-c2b8a37d6a6a?w=800';
    default:
      return 'https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=800';
  }
}
