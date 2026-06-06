import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class TrevoAnalyticsApp extends StatelessWidget {
  const TrevoAnalyticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Trevo Analytics',
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: AppRoutes.login,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
