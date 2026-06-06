import 'package:dashboard_analitycs/features/screens/auth/login_responsive_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dashboard_analitycs/core/exports/main_routes_export.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        builder: (context, state) => const LoginResponsiveScreen(),
      ),
      GoRoute(
        path: dashboard,
        builder: (context, state) => const DashboardResumeScreen(),
      ),
      GoRoute(
        path: home,
        redirect: (context, state) => login,
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Ruta no encontrada: ${state.matchedLocation}'),
      ),
    ),
  );
}
