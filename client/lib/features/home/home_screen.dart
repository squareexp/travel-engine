import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/brand.dart';
import '../../shared/widgets/category_chip.dart';
import '../../shared/widgets/featured_card.dart';
import '../../shared/widgets/listing_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinations = ref.watch(destinationsProvider);
    final listings = ref.watch(featuredListingsProvider);

    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: TwendeColors.primary,
          onRefresh: () async {
            ref.invalidate(destinationsProvider);
            ref.invalidate(featuredListingsProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TwendeSpacing.xl,
                  vertical: TwendeSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Expanded(
                        child: TwendeBrand(
                          size: 26,
                          subtitle: 'Discover Zanzibar. Explore Tanzania.',
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: TwendeColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(
                            TwendeSpacing.radiusPill,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(IconsaxPlusLinear.notification),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TwendeSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(child: _SearchField()),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  TwendeSpacing.xl,
                  TwendeSpacing.lg,
                  TwendeSpacing.xl,
                  TwendeSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(child: _CategoryRow()),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TwendeSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: FeaturedCard(
                    title: 'Zanzibar Beaches',
                    subtitle: 'Turquoise waters. White sand. Pure paradise.',
                    imageUrl:
                        'https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=1200',
                    onTap: () {},
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  TwendeSpacing.xl,
                  TwendeSpacing.xxl,
                  TwendeSpacing.xl,
                  TwendeSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader('Explore Tanzania'),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TwendeSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: destinations.when(
                    loading: () => _LoadingRow(),
                    error: (_, _) =>
                        const _EmptyHint(text: 'Couldn\'t load destinations'),
                    data: (items) => items.isEmpty
                        ? const _EmptyHint(text: 'No destinations yet')
                        : SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: TwendeSpacing.md),
                              itemBuilder: (_, i) {
                                final d = items[i];
                                return _DestinationTile(
                                  name: d.name,
                                  subtitle: d.region ?? d.country,
                                  imageUrl: d.imageUrls.isNotEmpty
                                      ? d.imageUrls.first
                                      : 'https://images.unsplash.com/photo-1568126879226-7e937ae84927?w=600',
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  TwendeSpacing.xl,
                  TwendeSpacing.xxl,
                  TwendeSpacing.xl,
                  TwendeSpacing.md,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader('Top Picks in Zanzibar'),
                ),
              ),
              listings.when(
                loading: () => SliverToBoxAdapter(child: _LoadingRow()),
                error: (_, _) => const SliverToBoxAdapter(
                  child: _EmptyHint(text: 'Couldn\'t load listings'),
                ),
                data: (items) => items.isEmpty
                    ? const SliverToBoxAdapter(
                        child: _EmptyHint(text: 'No listings yet'),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                          TwendeSpacing.xl,
                          0,
                          TwendeSpacing.xl,
                          TwendeSpacing.xxxl,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: TwendeSpacing.lg,
                                crossAxisSpacing: TwendeSpacing.lg,
                                childAspectRatio: 0.72,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => ListingCard(
                              listing: items[i],
                              onTap: () => ctx.push('/listings/${items[i].id}'),
                            ),
                            childCount: items.length,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search destinations, hotels, activities…',
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: TwendeSpacing.md),
          child: Icon(
            IconsaxPlusLinear.search_normal_1,
            color: TwendeColors.textTertiary,
          ),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: TwendeSpacing.sm),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: TwendeColors.primary,
              borderRadius: BorderRadius.circular(TwendeSpacing.radiusSm),
            ),
            child: const Icon(
              IconsaxPlusLinear.setting_4,
              color: TwendeColors.textInverse,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();

  @override
  Widget build(BuildContext context) {
    final categories = const [
      ('Beaches', IconsaxPlusLinear.sun_1),
      ('Safari', IconsaxPlusLinear.tree),
      ('Stone Town', IconsaxPlusLinear.building_3),
      ('Hotels', IconsaxPlusLinear.house),
      ('Transfers', IconsaxPlusLinear.car),
    ];
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: TwendeSpacing.md),
        itemBuilder: (_, i) {
          final (label, icon) = categories[i];
          return CategoryChip(label: label, icon: icon);
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: TwendeTypography.h3),
        Text(
          'View all',
          style: TwendeTypography.caption.copyWith(
            color: TwendeColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DestinationTile extends StatelessWidget {
  const _DestinationTile({
    required this.name,
    required this.subtitle,
    required this.imageUrl,
  });

  final String name;
  final String subtitle;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
        color: TwendeColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: TwendeColors.surfaceMuted),
            errorWidget: (_, _, _) =>
                Container(color: TwendeColors.surfaceMuted),
          ),
          Positioned(
            left: TwendeSpacing.md,
            right: TwendeSpacing.md,
            bottom: TwendeSpacing.md,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: TwendeSpacing.md,
                vertical: TwendeSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: TwendeColors.textInverse,
                borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TwendeTypography.title,
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TwendeTypography.caption,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: TwendeSpacing.md),
        itemBuilder: (_, _) => Container(
          width: 180,
          decoration: BoxDecoration(
            color: TwendeColors.surfaceMuted,
            borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TwendeSpacing.lg),
      decoration: BoxDecoration(
        color: TwendeColors.surfaceMuted,
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
      ),
      child: Text(text, style: TwendeTypography.body),
    );
  }
}
