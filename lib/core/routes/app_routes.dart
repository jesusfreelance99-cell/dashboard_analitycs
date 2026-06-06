import 'package:dashboard_analitycs/features/screens/auth/login_responsive_screen.dart';
import 'package:flutter/material.dart';
import 'package:dashboard_analitycs/core/exports/main_routes_export.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String home = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(
          builder: (_) => const LoginResponsiveScreen(),
          settings: settings,
        );
      case dashboard:
      case home:
        return MaterialPageRoute(
          builder: (_) => const DashboardResumeScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
