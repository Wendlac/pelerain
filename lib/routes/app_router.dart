import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/screens/splash_screen.dart';
import '../features/onboarding/screens/onboarding_screen.dart';
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

class AppRouter {
  static final _rootKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
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
}

// ─── Main shell with bottom nav ──────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // content flows under the floating nav
      body: widget.child,
      bottomNavigationBar: _FloatingPillNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          HapticService.selection();
          setState(() => _currentIndex = index);
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
