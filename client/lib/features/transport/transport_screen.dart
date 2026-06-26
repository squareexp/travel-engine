import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/app_sheet.dart';

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cars = ref.watch(carsProvider);
    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: TwendeColors.primary,
          onRefresh: () async => ref.invalidate(carsProvider),
          child: ListView(
            padding: const EdgeInsets.all(TwendeSpacing.xl),
            children: [
              Text('Car Hire & Transfers', style: TwendeTypography.h1),
              const SizedBox(height: TwendeSpacing.xs),
              Text(
                'Airport transfers, day rentals and chauffeur-driven trips.',
                style: TwendeTypography.body,
              ),
              const SizedBox(height: TwendeSpacing.lg),
              _quickTile(
                context,
                icon: IconsaxPlusLinear.airplane_square,
                title: 'Airport Transfer',
                subtitle: 'Arrivals & departures from ZNZ',
              ),
              const SizedBox(height: TwendeSpacing.sm),
              _quickTile(
                context,
                icon: IconsaxPlusLinear.car,
                title: 'Day Rental',
                subtitle: 'Self-drive or with a driver, 8h package',
              ),
              const SizedBox(height: TwendeSpacing.sm),
              _quickTile(
                context,
                icon: IconsaxPlusLinear.location,
                title: 'Point-to-point',
                subtitle: 'One-way intercity transfer',
              ),
              const SizedBox(height: TwendeSpacing.xxl),
              Text('Available cars', style: TwendeTypography.h3),
              const SizedBox(height: TwendeSpacing.md),
              cars.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TwendeColors.primary),
                ),
                error: (e, _) => _carsUnavailable(),
                data: (items) => items.isEmpty
                    ? _carsUnavailable()
                    : Column(
                        children: items.map((c) => _CarTile(data: c)).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Material(
      color: TwendeColors.surface,
      borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
        onTap: () => AppSheet.show(
          context,
          title: title,
          message: '$subtitle. Tap "Available cars" below to pick a vehicle.',
          kind: SheetKind.info,
        ),
        child: Padding(
          padding: const EdgeInsets.all(TwendeSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: TwendeColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
                ),
                child: Icon(icon, color: TwendeColors.primary),
              ),
              const SizedBox(width: TwendeSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TwendeTypography.title),
                    Text(subtitle, style: TwendeTypography.caption),
                  ],
                ),
              ),
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: TwendeColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carsUnavailable() {
    return Container(
      padding: const EdgeInsets.all(TwendeSpacing.lg),
      decoration: BoxDecoration(
        color: TwendeColors.surfaceMuted,
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
      ),
      child: const Row(
        children: [
          Icon(IconsaxPlusLinear.info_circle, color: TwendeColors.primary),
          SizedBox(width: TwendeSpacing.md),
          Expanded(
            child: Text(
              'Car hire (Pistoni) is not running. Start the Go API on :1010 to load live cars.',
            ),
          ),
        ],
      ),
    );
  }
}

class _CarTile extends StatelessWidget {
  const _CarTile({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final title = data['name'] as String? ?? data['model'] as String? ?? 'Car';
    final price = data['pricePerDay'] ?? data['daily_rate'];
    final imageUrl =
        data['imageUrl'] as String? ?? data['image_url'] as String?;
    return Container(
      margin: const EdgeInsets.only(bottom: TwendeSpacing.md),
      decoration: BoxDecoration(
        color: TwendeColors.surface,
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 90,
            child: imageUrl != null
                ? CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                : Container(
                    color: TwendeColors.surfaceMuted,
                    child: const Icon(
                      IconsaxPlusLinear.car,
                      color: TwendeColors.textTertiary,
                    ),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(TwendeSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TwendeTypography.title),
                  if (price != null)
                    Text(
                      '\$$price / day',
                      style: TwendeTypography.caption.copyWith(
                        color: TwendeColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
