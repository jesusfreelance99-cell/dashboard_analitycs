class AppConstants {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // Border Radius
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 10.0; // inputs/botones Trevo
  static const double radiusXl = 14.0; // tarjetas preview
  static const double radiusXxl = 24.0;
  static const double radiusPill = 100.0;

  // Elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration loginLoadingDuration = Duration(milliseconds: 780);
  static const Duration loginVeilDuration = Duration(milliseconds: 460);

  // Breakpoints (responsive)
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 900.0; // login oculta panel derecho
  static const double breakpointDesktop = 1024.0;

  // Login layout
  static const double loginFormMaxWidth = 360.0;
  static const double loginFormPaddingH = 48.0;
  static const double loginFormPaddingV = 40.0;
  static const double loginPanelPaddingH = 56.0;
  static const double loginPanelPaddingV = 52.0;

  // App info
  static const String appName = 'Trevo Analytics';
  static const String appVersion = '1.0.0';
}
