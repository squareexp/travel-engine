import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/repositories.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/listing_card.dart';

const _filters = [
  ('All', null, IconsaxPlusLinear.element_3),
  ('Sites', 'site', IconsaxPlusLinear.building_3),
  ('Experiences', 'experience', IconsaxPlusLinear.activity),
  ('Trips', 'trip', IconsaxPlusLinear.map_1),
  ('Safari', 'safari', IconsaxPlusLinear.tree),
];

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _ctl = TextEditingController();
  String? _type;
  String _text = '';
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _text = value.trim());
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = SearchQuery(type: _type, text: _text);
    final results = ref.watch(searchResultsProvider(query));

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
                  Text('Explore', style: TwendeTypography.h1),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TwendeSpacing.xl),
              child: TextField(
                controller: _ctl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search Zanzibar & Tanzania…',
                  prefixIcon: const Icon(IconsaxPlusLinear.search_normal_1),
                  suffixIcon: _ctl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(IconsaxPlusLinear.close_circle),
                          onPressed: () {
                            _ctl.clear();
                            setState(() => _text = '');
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: TwendeSpacing.md),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: TwendeSpacing.xl,
                ),
                itemCount: _filters.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: TwendeSpacing.sm),
                itemBuilder: (_, i) {
                  final (label, value, icon) = _filters[i];
                  final selected = _type == value;
                  return GestureDetector(
                    onTap: () => setState(() => _type = value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TwendeSpacing.md,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? TwendeColors.primary
                            : TwendeColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(
                          TwendeSpacing.radiusPill,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: selected
                                ? TwendeColors.textInverse
                                : TwendeColors.textPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TwendeTypography.label.copyWith(
                              color: selected
                                  ? TwendeColors.textInverse
                                  : TwendeColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: TwendeSpacing.md),
            Expanded(
              child: results.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TwendeColors.primary),
                ),
                error: (_, _) => const _Empty(
                  icon: IconsaxPlusLinear.warning_2,
                  text: 'Couldn\'t load search results',
                ),
                data: (items) => items.isEmpty
                    ? const _Empty(
                        icon: IconsaxPlusLinear.search_status,
                        text: 'No results — try a different search',
                      )
                    : RefreshIndicator(
                        color: TwendeColors.primary,
                        onRefresh: () async =>
                            ref.invalidate(searchResultsProvider(query)),
                        child: GridView.builder(
                          padding: const EdgeInsets.all(TwendeSpacing.xl),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: TwendeSpacing.lg,
                                crossAxisSpacing: TwendeSpacing.lg,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: items.length,
                          itemBuilder: (ctx, i) => ListingCard(
                            listing: items[i],
                            onTap: () => ctx.push('/listings/${items[i].id}'),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: TwendeColors.textTertiary),
          const SizedBox(height: TwendeSpacing.md),
          Text(text, style: TwendeTypography.body),
        ],
      ),
    );
  }
}
