import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/search/screens/home_screen.dart';
import '../features/search/screens/search_results_screen.dart';
import '../features/booking/screens/trip_details_screen.dart';
import '../features/booking/screens/booking_form_screen.dart';
import '../features/booking/screens/booking_success_screen.dart';
import '../features/reservations/screens/my_reservations_screen.dart';
import '../features/reservations/screens/reservation_detail_screen.dart';
import '../features/account/screens/account_screen.dart';
import '../features/companies/screens/company_detail_screen.dart';
import '../shared/models/trip.dart';
import '../shared/models/reservation.dart';
import '../shared/models/company.dart';
import '../shared/providers/supabase_provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/haptic_service.dart';

// ─── Custom page transitions ─────────────────────────────────────────────────

/// Slide-from-right + fade for detail screens
CustomTransitionPage<T> _slidePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      );

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(position: offsetAnimation, child: child),
      );
    },
  );
}

/// Fade-only for main tab screens
CustomTransitionPage<T> _fadePage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

/// Slide-from-bottom for modals / success screens
CustomTransitionPage<T> _slideUpPage<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      final offsetAnimation = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));

      return SlideTransition(position: offsetAnimation, child: child);
    },
  );
}

// ─── Router ──────────────────────────────────────────────────────────────────

/// Routes that don't require an authenticated user.
/// Anything else triggers a redirect to /auth when there's no session.
const _publicRoutes = {'/splash', '/onboarding', '/auth'};

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod-aware GoRouter. The `refreshListenable` is wired to the Supabase
/// auth stream, so a sign-in / sign-out automatically re-evaluates redirects.
final goRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRefreshNotifier(
    ref.watch(supabaseClientProvider).auth.onAuthStateChange,
  );
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final session = ref.read(supabaseClientProvider).auth.currentSession;
      final loggedIn = session != null;
      final location = state.matchedLocation;

      // 1. Logged out + trying to access a protected page → send to /auth
      if (!loggedIn && !_publicRoutes.contains(location)) {
        return '/auth';
      }
      // 2. Already logged in but on the auth screen → go home
      if (loggedIn && location == '/auth') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const AuthScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadePage(
              context: context, state: state, child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/reservations',
            pageBuilder: (context, state) => _fadePage(
              context: context, state: state, child: const MyReservationsScreen(),
            ),
          ),
          GoRoute(
            path: '/account',
            pageBuilder: (context, state) => _fadePage(
              context: context, state: state, child: const AccountScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/search-results',
        pageBuilder: (context, state) => _slidePage(
          context: context, state: state, child: const SearchResultsScreen(),
        ),
      ),
      GoRoute(
        path: '/trip-details',
        pageBuilder: (context, state) {
          final trip = state.extra as Trip;
          return _slidePage(
            context: context,
            state: state,
            child: TripDetailsScreen(trip: trip),
          );
        },
      ),
      GoRoute(
        path: '/booking-form',
        pageBuilder: (context, state) {
          final trip = state.extra as Trip;
          return _slidePage(
            context: context,
            state: state,
            child: BookingFormScreen(trip: trip),
          );
        },
      ),
      GoRoute(
        path: '/booking-success',
        pageBuilder: (context, state) => _slideUpPage(
          context: context, state: state, child: const BookingSuccessScreen(),
        ),
      ),
      GoRoute(
        path: '/reservation-detail',
        pageBuilder: (context, state) {
          final reservation = state.extra as Reservation;
          return _slidePage(
            context: context,
            state: state,
            child: ReservationDetailScreen(reservation: reservation),
          );
        },
      ),
      GoRoute(
        path: '/company-detail',
        pageBuilder: (context, state) {
          final company = state.extra as Company;
          return _slidePage(
            context: context,
            state: state,
            child: CompanyDetailScreen(company: company),
          );
        },
      ),
    ],
  );
});

/// Bridges Supabase's auth stream into a Listenable that GoRouter can subscribe
/// to via `refreshListenable`. Whenever the auth state changes (sign-in,
/// sign-out, token refresh), the router re-evaluates its redirect logic.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ─── Main shell with bottom nav ──────────────────────────────────────────────

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Determine the active tab from the current route, not from local state —
    // that way the bottom nav stays in sync after deep links or back-nav.
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/reservations')) currentIndex = 1;
    if (location.startsWith('/account')) currentIndex = 2;

    return Scaffold(
      extendBody: true, // content flows under the floating nav
      body: child,
      bottomNavigationBar: _FloatingPillNav(
        currentIndex: currentIndex,
        onTap: (index) {
          HapticService.selection();
          switch (index) {
            case 0: context.go('/home');
            case 1: context.go('/reservations');
            case 2: context.go('/account');
          }
        },
      ),
    );
  }
}

// ─── Floating Pill Bottom Nav ─────────────────────────────────────────────────

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingPillNav({required this.currentIndex, required this.onTap});

  static const _items = [
    (icon: Icons.search_rounded,               label: 'Rechercher'),
    (icon: Icons.confirmation_number_outlined, label: 'Mes billets'),
    (icon: Icons.person_outline_rounded,       label: 'Mon compte'),
  ];

  @override
  Widget build(BuildContext context) {
    // Transparent wrapper so background shows through the margins
    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          // Horizontal margin + bottom gap = the "floating" look
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32), // pill shape
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 28,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: _items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final selected = currentIndex == i;
                return Expanded(
                  child: _PillNavTab(
                    icon: item.icon,
                    label: item.label,
                    selected: selected,
                    onTap: () => onTap(i),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillNavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          // Active tab gets a soft lavender pill highlight
          color: selected
              ? AppColors.primary.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey(selected),
                size: 22,
                color: selected
                    ? AppColors.primary
                    : const Color(0xFFAAAAAA),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : const Color(0xFFAAAAAA),
                letterSpacing: selected ? -0.3 : 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
