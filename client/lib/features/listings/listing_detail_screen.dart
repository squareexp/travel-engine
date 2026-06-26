import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import 'package:go_router/go_router.dart';

import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../favorites/favorites_store.dart';

class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingAsync = ref.watch(listingDetailProvider(id));
    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: listingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: TwendeColors.primary),
        ),
        error: (e, _) => Center(child: Text('Couldn\'t load: $e')),
        data: (listing) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              elevation: 0,
              backgroundColor: TwendeColors.background,
              leading: Padding(
                padding: const EdgeInsets.all(TwendeSpacing.sm),
                child: CircleAvatar(
                  backgroundColor: TwendeColors.textInverse,
                  child: IconButton(
                    icon: const Icon(
                      IconsaxPlusLinear.arrow_left_2,
                      color: TwendeColors.textPrimary,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(TwendeSpacing.sm),
                  child: CircleAvatar(
                    backgroundColor: TwendeColors.textInverse,
                    child: IconButton(
                      icon: Icon(
                        ref.watch(favoritesProvider).contains(listing.id)
                            ? IconsaxPlusBold.heart
                            : IconsaxPlusLinear.heart,
                        color: ref.watch(favoritesProvider).contains(listing.id)
                            ? TwendeColors.danger
                            : TwendeColors.textPrimary,
                      ),
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(listing.id),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl:
                      listing.heroImageUrl ??
                      'https://images.unsplash.com/photo-1580973193083-c2b8a37d6a6a?w=1200',
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: TwendeColors.surfaceMuted),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(TwendeSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(listing.title, style: TwendeTypography.h1),
                    if (listing.destinationName != null) ...[
                      const SizedBox(height: TwendeSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusLinear.location,
                            size: 16,
                            color: TwendeColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            listing.destinationName!,
                            style: TwendeTypography.body,
                          ),
                        ],
                      ),
                    ],
                    if (listing.averageRating != null) ...[
                      const SizedBox(height: TwendeSpacing.sm),
                      Row(
                        children: [
                          const Icon(
                            IconsaxPlusBold.star_1,
                            size: 16,
                            color: TwendeColors.star,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${listing.averageRating!.toStringAsFixed(1)}'
                            '${listing.reviewCount != null ? " (${listing.reviewCount} reviews)" : ""}',
                            style: TwendeTypography.body.copyWith(
                              color: TwendeColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: TwendeSpacing.xl),
                    _InfoChipsRow(listing: listing),
                    const SizedBox(height: TwendeSpacing.xl),
                    if (listing.description != null)
                      Text(
                        listing.description!,
                        style: TwendeTypography.bodyLarge.copyWith(
                          color: TwendeColors.textSecondary,
                        ),
                      ),
                    if (listing.inclusions.isNotEmpty) ...[
                      const SizedBox(height: TwendeSpacing.xxl),
                      Text('Inclusions', style: TwendeTypography.h3),
                      const SizedBox(height: TwendeSpacing.md),
                      ...listing.inclusions.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: TwendeSpacing.sm,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                IconsaxPlusLinear.tick_circle,
                                size: 18,
                                color: TwendeColors.success,
                              ),
                              const SizedBox(width: TwendeSpacing.sm),
                              Expanded(
                                child: Text(
                                  item,
                                  style: TwendeTypography.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: listingAsync.maybeWhen(
        data: (listing) => Container(
          padding: const EdgeInsets.fromLTRB(
            TwendeSpacing.xl,
            TwendeSpacing.md,
            TwendeSpacing.xl,
            TwendeSpacing.xxl,
          ),
          decoration: const BoxDecoration(
            color: TwendeColors.surface,
            border: Border(top: BorderSide(color: TwendeColors.borderSubtle)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('From', style: TwendeTypography.caption),
                    Row(
                      children: [
                        Text(
                          listing.formattedPrice,
                          style: TwendeTypography.h2.copyWith(
                            color: TwendeColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('/ person', style: TwendeTypography.caption),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: TwendeSpacing.lg),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      '/listings/${listing.id}/book',
                      extra: listing,
                    ),
                    child: Text('Book Now', style: TwendeTypography.button),
                  ),
                ),
              ],
            ),
          ),
        ),
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}

class _InfoChipsRow extends StatelessWidget {
  const _InfoChipsRow({required this.listing});
  final dynamic listing;

  @override
  Widget build(BuildContext context) {
    final chips = <(IconData, String, String)>[
      (
        IconsaxPlusLinear.clock,
        'Duration',
        listing.durationHours != null
            ? '${listing.durationHours} hours'
            : 'Flexible',
      ),
      (
        IconsaxPlusLinear.people,
        'Group Size',
        listing.capacity != null ? 'Up to ${listing.capacity}' : '—',
      ),
      (
        IconsaxPlusLinear.dollar_circle,
        'Price',
        'From ${listing.formattedPrice}',
      ),
    ];
    return Row(
      children: [
        for (final c in chips) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: TwendeSpacing.md,
                horizontal: TwendeSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: TwendeColors.surfaceMuted,
                borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
              ),
              child: Column(
                children: [
                  Icon(c.$1, size: 18, color: TwendeColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    c.$2,
                    style: TwendeTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    c.$3,
                    style: TwendeTypography.label.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          if (c != chips.last) const SizedBox(width: TwendeSpacing.sm),
        ],
      ],
    );
  }
}
