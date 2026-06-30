import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../../api/api_config.dart';
import '../../auth/auth_controller.dart';
import '../../design/colors.dart';
import '../../design/spacing.dart';
import '../../design/typography.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/brand.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  String? _lastError;

  @override
  Widget build(BuildContext context) {
    // Show errors as a bottom sheet so the layout never deforms.
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.error &&
          next.error != null &&
          next.error != _lastError) {
        _lastError = next.error;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          AppSheet.show(
            context,
            title: 'Sign-in failed',
            message: next.error,
            kind: SheetKind.error,
            primaryLabel: 'Try again',
          );
        });
      }
    });

    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    return Scaffold(
      backgroundColor: TwendeColors.background,
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1559825481-12a05cc00344?w=1200',
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: TwendeColors.surfaceMuted),
                  errorWidget: (_, _, _) =>
                      Container(color: TwendeColors.surfaceMuted),
                ),
                Container(color: const Color(0x55000000)),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TwendeSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const TwendeBrand(
                          size: 34,
                          color: TwendeColors.textInverse,
                          subtitle: 'One App. Zanzibar & Tanzania.',
                        ),
                        const SizedBox(height: TwendeSpacing.md),
                        Text(
                          'Discover Zanzibar.\nExplore Tanzania.',
                          style: TwendeTypography.h1.copyWith(
                            color: TwendeColors.textInverse,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TwendeSpacing.xxl,
                  TwendeSpacing.xl,
                  TwendeSpacing.xxl,
                  TwendeSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Welcome', style: TwendeTypography.h2),
                    const SizedBox(height: TwendeSpacing.xs),
                    Text(
                      ApiConfig.devBypassAuth
                          ? 'Skip auth and explore the prototype.'
                          : 'Sign in securely with your Base account.',
                      style: TwendeTypography.body,
                    ),
                    const Spacer(),
                    if (ApiConfig.devBypassAuth) ...[
                      ElevatedButton.icon(
                        onPressed: controller.signInAsDev,
                        icon: const Icon(
                          IconsaxPlusBold.flash_1,
                          color: TwendeColors.textInverse,
                          size: 18,
                        ),
                        label: Text(
                          'Enter as Preview Traveler',
                          style: TwendeTypography.button,
                        ),
                      ),
                      const SizedBox(height: TwendeSpacing.md),
                      OutlinedButton(
                        onPressed: auth.status == AuthStatus.signingIn
                            ? null
                            : controller.signInWithBaseIdP,
                        child: Text(
                          'Continue with Base (IdP)',
                          style: TwendeTypography.button.copyWith(
                            color: TwendeColors.primary,
                          ),
                        ),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: auth.status == AuthStatus.signingIn
                            ? null
                            : controller.signInWithBaseIdP,
                        child: auth.status == AuthStatus.signingIn
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                    TwendeColors.textInverse,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    IconsaxPlusBold.shield_tick,
                                    color: TwendeColors.textInverse,
                                    size: 18,
                                  ),
                                  const SizedBox(width: TwendeSpacing.sm),
                                  Text(
                                    'Continue with Base',
                                    style: TwendeTypography.button,
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: TwendeSpacing.md),
                      OutlinedButton(
                        onPressed: () =>
                            _showDevSignInSheet(context, controller),
                        child: const Text('Dev sign-in (email/password)'),
                      ),
                    ],
                    const SizedBox(height: TwendeSpacing.lg),
                    Text(
                      'By continuing you agree to the Twende Terms & Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: TwendeTypography.caption,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDevSignInSheet(BuildContext context, AuthController controller) {
    final email = TextEditingController(text: 'traveler@test.com');
    final password = TextEditingController(text: 'Test1234!');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: TwendeColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(TwendeSpacing.radiusXl),
              ),
            ),
            padding: const EdgeInsets.all(TwendeSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: TwendeSpacing.lg),
                    decoration: BoxDecoration(
                      color: TwendeColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Dev sign-in', style: TwendeTypography.h3),
                const SizedBox(height: TwendeSpacing.md),
                TextField(
                  controller: email,
                  decoration: const InputDecoration(hintText: 'email'),
                ),
                const SizedBox(height: TwendeSpacing.sm),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'password'),
                ),
                const SizedBox(height: TwendeSpacing.lg),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    controller.signInWithEmail(email.text, password.text);
                  },
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
