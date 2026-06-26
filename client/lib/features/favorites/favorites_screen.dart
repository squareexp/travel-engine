import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/listing_card.dart';
import 'favorites_store.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider);
    final featured =
        ref.watch(featuredListingsProvider).valueOrNull ?? const [];
    final liked = featured.where((l) => ids.contains(l.id)).toList();

    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TwendeSpacing.xl,
            TwendeSpacing.lg,
            TwendeSpacing.xl,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Favorites', style: TwendeTypography.h1),
              const SizedBox(height: TwendeSpacing.xs),
              Text(
                '${liked.length} saved listings',
                style: TwendeTypography.body,
              ),
              const SizedBox(height: TwendeSpacing.lg),
              Expanded(
                child: liked.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              IconsaxPlusLinear.heart,
                              size: 56,
                              color: TwendeColors.textTertiary,
                            ),
                            const SizedBox(height: TwendeSpacing.md),
                            Text(
                              'Nothing saved yet',
                              style: TwendeTypography.h3,
                            ),
                            const SizedBox(height: TwendeSpacing.xs),
                            Text(
                              'Tap the heart on any listing to save it here.',
                              textAlign: TextAlign.center,
                              style: TwendeTypography.body,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(
                          bottom: TwendeSpacing.xxxl,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: TwendeSpacing.lg,
                              crossAxisSpacing: TwendeSpacing.lg,
                              childAspectRatio: 0.72,
                            ),
                        itemCount: liked.length,
                        itemBuilder: (ctx, i) => ListingCard(
                          listing: liked[i],
                          onTap: () => ctx.push('/listings/${liked[i].id}'),
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
