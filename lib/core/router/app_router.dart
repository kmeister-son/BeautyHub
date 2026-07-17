import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/booking/presentation/booking_screen.dart';
import '../../features/bookings/presentation/bookings_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/salon/presentation/salon_details_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/splash/presentation/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ]),
      ],
    ),
    // Full-screen flows (no bottom bar) live on the root navigator.
    GoRoute(
      path: '/salon/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          SalonDetailsScreen(salonId: state.pathParameters['id']!),
      routes: [
        GoRoute(
          path: 'book',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => BookingScreen(
            salonId: state.pathParameters['id']!,
            serviceIds: (state.uri.queryParameters['services'] ?? '')
                .split(',')
                .where((id) => id.isNotEmpty)
                .toList(),
          ),
        ),
      ],
    ),
  ],
);
