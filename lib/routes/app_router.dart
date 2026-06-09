import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/search/screens/home_screen.dart';
import '../features/search/screens/search_loading_screen.dart';
import '../features/search/screens/search_results_screen.dart';
import '../features/booking/screens/trip_details_screen.dart';
import '../features/companies/screens/company_detail_screen.dart';
import '../shared/models/trip.dart';
import '../shared/models/company.dart';

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

/// Fade-only for the splash → home transition
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

// ─── Router ──────────────────────────────────────────────────────────────────
//
// MVP flow: splash → home (search) → results → trip details → company details.
// No auth, no tabs, no bottom navigation — every screen is a regular pushed
// route so the back arrow / system back walks the user back step by step.

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/search-loading',
        pageBuilder: (context, state) => _fadePage(
          context: context, state: state, child: const SearchLoadingScreen(),
        ),
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
