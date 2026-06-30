import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/models.dart';
import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/app_surface.dart';
import '../../shared/widgets/trip_timeline_card.dart';

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(myBookingsProvider);
    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TwendeSpacing.xl,
                TwendeSpacing.lg,
                TwendeSpacing.xl,
                TwendeSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('My trip', style: TwendeTypography.h1)),
                  IconButton(
                    tooltip: 'Share trip',
                    onPressed: () {},
                    icon: const Icon(IconsaxPlusLinear.share),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TwendeSpacing.xl),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Itinerary')),
                  ButtonSegment(value: 1, label: Text('Bookings')),
                  ButtonSegment(value: 2, label: Text('Saved')),
                ],
                selected: {_tab},
                showSelectedIcon: false,
                onSelectionChanged: (value) =>
                    setState(() => _tab = value.first),
              ),
            ),
            const SizedBox(height: TwendeSpacing.md),
            Expanded(
              child: bookings.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TwendeColors.accent),
                ),
                error: (_, _) => const _TripEmpty(
                  icon: IconsaxPlusLinear.warning_2,
                  title: 'We could not load your trip',
                  detail: 'Pull to refresh and try again.',
                ),
                data: (items) => switch (_tab) {
                  0 => _Itinerary(items: items),
                  1 => _BookingList(items: items),
                  _ => const _TripEmpty(
                    icon: IconsaxPlusLinear.heart,
                    title: 'Saved experiences',
                    detail: 'Tap the heart on an experience to keep it here.',
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Itinerary extends StatelessWidget {
  const _Itinerary({required this.items});
  final List<Booking> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TripEmpty(
        icon: IconsaxPlusLinear.calendar_remove,
        title: 'Your itinerary is clear',
        detail: 'When you book an experience, its plan will appear here.',
      );
    }
    return RefreshIndicator(
      color: TwendeColors.accent,
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.all(TwendeSpacing.xl),
        children: [
          AppSurface(
            emphasis: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UP NEXT',
                  style: TwendeTypography.caption.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: TwendeSpacing.sm),
                Text(
                  items.first.listingTitle,
                  style: TwendeTypography.h2.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.first.travelDate} · ${items.first.guests} guest${items.first.guests == 1 ? '' : 's'}',
                  style: TwendeTypography.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: TwendeSpacing.xxl),
          Text('Your schedule', style: TwendeTypography.h2),
          const SizedBox(height: TwendeSpacing.md),
          for (var i = 0; i < items.length; i++)
            TripTimelineCard(
              date: items[i].travelDate,
              title: items[i].listingTitle,
              detail:
                  '${items[i].guests} guest${items[i].guests == 1 ? '' : 's'} · ${items[i].status}',
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({required this.items});
  final List<Booking> items;
  @override
  Widget build(BuildContext context) => items.isEmpty
      ? const _TripEmpty(
          icon: IconsaxPlusLinear.ticket,
          title: 'No bookings yet',
          detail: 'Your confirmed experiences will live here.',
        )
      : ListView.separated(
          padding: const EdgeInsets.all(TwendeSpacing.xl),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: TwendeSpacing.md),
          itemBuilder: (_, i) => AppSurface(
            child: Row(
              children: [
                const Icon(
                  IconsaxPlusLinear.calendar_2,
                  color: TwendeColors.accent,
                ),
                const SizedBox(width: TwendeSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[i].listingTitle,
                        style: TwendeTypography.title,
                      ),
                      Text(
                        '${items[i].travelDate} · ${items[i].guests} guests',
                        style: TwendeTypography.caption,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: items[i].status),
              ],
            ),
          ),
        );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'confirmed' || 'completed' => TwendeColors.success,
      'cancelled' => TwendeColors.danger,
      _ => TwendeColors.warning,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusPill),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TwendeTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TripEmpty extends StatelessWidget {
  const _TripEmpty({
    required this.icon,
    required this.title,
    required this.detail,
  });
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(TwendeSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: TwendeColors.textTertiary),
          const SizedBox(height: TwendeSpacing.lg),
          Text(title, style: TwendeTypography.h3),
          const SizedBox(height: TwendeSpacing.sm),
          Text(
            detail,
            textAlign: TextAlign.center,
            style: TwendeTypography.body,
          ),
        ],
      ),
    ),
  );
}
