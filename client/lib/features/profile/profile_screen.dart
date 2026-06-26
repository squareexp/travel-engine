import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../auth/auth_controller.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/brand.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(TwendeSpacing.xl),
          children: [
            const TwendeBrand(size: 26, subtitle: 'Your account'),
            const SizedBox(height: TwendeSpacing.xxl),
            Container(
              padding: const EdgeInsets.all(TwendeSpacing.lg),
              decoration: BoxDecoration(
                color: TwendeColors.surface,
                borderRadius: BorderRadius.circular(TwendeSpacing.radiusLg),
                border: Border.all(color: TwendeColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: TwendeColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (auth.userName?.isNotEmpty == true
                              ? auth.userName![0]
                              : 'T')
                          .toUpperCase(),
                      style: TwendeTypography.h3.copyWith(
                        color: TwendeColors.textInverse,
                      ),
                    ),
                  ),
                  const SizedBox(width: TwendeSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName ?? 'Traveler',
                          style: TwendeTypography.title,
                        ),
                        if (auth.userEmail != null)
                          Text(
                            auth.userEmail!,
                            style: TwendeTypography.caption,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: TwendeSpacing.xxl),
            _Tile(
              icon: IconsaxPlusLinear.heart,
              title: 'Favorites',
              onTap: () {},
            ),
            _Tile(
              icon: IconsaxPlusLinear.wallet_2,
              title: 'Payments',
              onTap: () {},
            ),
            _Tile(
              icon: IconsaxPlusLinear.notification,
              title: 'Notifications',
              onTap: () {},
            ),
            _Tile(
              icon: IconsaxPlusLinear.security_safe,
              title: 'Security',
              onTap: () {},
            ),
            _Tile(
              icon: IconsaxPlusLinear.message_question,
              title: 'Help & Support',
              onTap: () {},
            ),
            const SizedBox(height: TwendeSpacing.xxxl),
            OutlinedButton.icon(
              icon: const Icon(
                IconsaxPlusLinear.logout,
                color: TwendeColors.danger,
              ),
              label: Text(
                'Sign out',
                style: TwendeTypography.button.copyWith(
                  color: TwendeColors.danger,
                ),
              ),
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).signOut(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(TwendeSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: TwendeSpacing.md,
            horizontal: TwendeSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, color: TwendeColors.textPrimary),
              const SizedBox(width: TwendeSpacing.md),
              Expanded(child: Text(title, style: TwendeTypography.bodyLarge)),
              const Icon(
                IconsaxPlusLinear.arrow_right_3,
                color: TwendeColors.textTertiary,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
