import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'api/models.dart';
import 'auth/auth_controller.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/bookings/create_booking_screen.dart';
import 'features/home/root_shell.dart';
import 'features/listings/listing_detail_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRouterNotifier(ref);
  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loggingIn = state.matchedLocation == '/sign-in';
      if (auth.status == AuthStatus.unknown) return null;
      if (auth.status != AuthStatus.signedIn && !loggingIn) return '/sign-in';
      if (auth.status == AuthStatus.signedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const RootShell()),
      GoRoute(path: '/sign-in', builder: (_, __) => const SignInScreen()),
      GoRoute(
        path: '/listings/:id',
        builder: (_, s) => ListingDetailScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/listings/:id/book',
        builder: (_, s) {
          final listing = s.extra as Listing?;
          return listing == null
              ? const Scaffold(
                  body: Center(child: Text('Missing listing data')))
              : CreateBookingScreen(listing: listing);
        },
      ),
    ],
  );
});

class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(this._ref) {
    _ref.listen<AuthState>(authControllerProvider, (_, __) {
      notifyListeners();
    });
  }
  final Ref _ref;
}
