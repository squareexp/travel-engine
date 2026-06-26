import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import 'app_surface.dart';

class TripTimelineCard extends StatelessWidget {
  const TripTimelineCard({
    super.key,
    required this.date,
    required this.title,
    required this.detail,
    this.isLast = false,
  });

  final String date;
  final String title;
  final String detail;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              const SizedBox(height: 17),
              const DecoratedBox(
                decoration: BoxDecoration(
                  color: TwendeColors.accent,
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 12, height: 12),
              ),
              if (!isLast)
                Container(height: 58, width: 2, color: TwendeColors.border),
            ],
          ),
        ),
        const SizedBox(width: TwendeSpacing.md),
        Expanded(
          child: AppSurface(
            padding: const EdgeInsets.all(TwendeSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TwendeTypography.caption.copyWith(
                    color: TwendeColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(title, style: TwendeTypography.title),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      IconsaxPlusLinear.location,
                      size: 15,
                      color: TwendeColors.textTertiary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TwendeTypography.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'Trip timeline', group: 'Trips', size: Size(390, 250))
Widget tripTimelineCardPreview() => const MaterialApp(
  home: Scaffold(
    backgroundColor: TwendeColors.background,
    body: Padding(
      padding: EdgeInsets.all(TwendeSpacing.xl),
      child: TripTimelineCard(
        date: 'FRI, 18 JUL',
        title: 'Mnemba Island snorkel',
        detail: 'Nungwi · 2 guests · Confirmed',
      ),
    ),
  ),
);
