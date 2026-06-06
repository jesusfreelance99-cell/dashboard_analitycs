import 'package:flutter/material.dart';

class AppColors {
  // ── Trevo brand tokens ──────────────────────────────────────────
  static const Color pink = Color(0xFFfd386f); // rosa primario
  static const Color pinkDark = Color(0xFFc3124f); // hover/dark rosa
  static const Color pinkBright = Color(0xFFff376e); // inicio gradiente marca
  static const Color pinkLight = Color(0xFFffd9e4); // énfasis headline

  // Gradiente del panel de marca (157°)
  static const List<Color> brandGradient = [
    Color(0xFFff376e), // 0%
    Color(0xFFe9295f), // 24%
    Color(0xFFa22346), // 52%
    Color(0xFF4e1226), // 78%
    Color(0xFF16050b), // 100%
  ];

  // ── Tinta / texto ───────────────────────────────────────────────
  static const Color ink = Color(0xFF1a1a18); // texto principal
  static const Color ink2 = Color(0xFF6b6b68); // texto secundario
  static const Color ink3 = Color(0xFF9e9d99); // placeholder / terciario

  // ── Superficies / campos ────────────────────────────────────────
  static const Color fieldBg = Color(0xFFfaf9f8); // fondo input reposo
  static const Color fieldFocus = Color(0xFFffffff); // fondo input focus
  static const Color white = Color(0xFFffffff);

  // ── Líneas / bordes ─────────────────────────────────────────────
  static const Color line = Color(0x1A000000); // rgba(0,0,0,0.10)
  static const Color line2 = Color(0x29000000); // rgba(0,0,0,0.16)

  // ── Estados ─────────────────────────────────────────────────────
  static const Color success = Color(0xFF15803d); // deltas positivos
  static const Color danger = Color(0xFFd22b3f); // error / validación
  static const Color liveGreen = Color(0xFF4ade80); // badge En vivo

  // ── Colores de datos (embudo / charts) ──────────────────────────
  static const Color chartBlue = Color(0xFF378ADD);
  static const Color chartGreen = Color(0xFF1D9E75);
  static const Color chartPurple = Color(0xFF7F77DD);
  static const Color chartPink = Color(0xFFD4537E);
  static const Color chartAmber = Color(0xFFEF9F27);
  static const Color chartRed = Color(0xFFE24B4A);
  static const Color chartOlive = Color(0xFF639922);

  // ── Heredados (retrocompatibilidad con widgets existentes) ───────
  static const Color magentaVibrante = pink;
  static const Color rosaBrillante = Color(0xFFFF4081);
  static const Color rosaMedio = Color(0xFFE81E63);
  static const Color rosaClaro = pinkLight;
  static const Color borgognaOscuro = Color(0xFF880E4F);
  static const Color rojoOscuro = Color(0xFF660033);
  static const Color negro = ink;
  static const Color blanco = white;
  static const Color grisClaro = fieldBg;
  static const Color grisMedio = ink3;
  static const Color grisOscuro = ink2;
  static const Color error = danger;
  static const Color info = Color(0xFF29B6F6);
  static const Color warning = Color(0xFFFFA726);

  // ── ColorScheme light ───────────────────────────────────────────
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: pink,
    onPrimary: white,
    primaryContainer: Color(0xFFffd9e4),
    onPrimaryContainer: ink,
    secondary: pinkDark,
    onSecondary: white,
    secondaryContainer: Color(0xFFffd9e4),
    onSecondaryContainer: ink,
    tertiary: Color(0xFF660033),
    onTertiary: white,
    tertiaryContainer: Color(0xFFffd9e4),
    onTertiaryContainer: ink,
    error: danger,
    onError: white,
    errorContainer: Color(0xFFfef4f4),
    onErrorContainer: danger,
    surface: white,
    onSurface: ink,
    surfaceContainerHighest: fieldBg,
    onSurfaceVariant: ink2,
    outline: ink3,
    outlineVariant: line2,
    scrim: ink,
    inverseSurface: Color(0xFF313033),
    onInverseSurface: white,
    inversePrimary: pinkLight,
    shadow: ink,
  );

  // ── ColorScheme dark ────────────────────────────────────────────
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: pinkLight,
    onPrimary: Color(0xFF880E4F),
    primaryContainer: pink,
    onPrimaryContainer: white,
    secondary: Color(0xFFFF4081),
    onSecondary: ink,
    secondaryContainer: Color(0xFFE81E63),
    onSecondaryContainer: white,
    tertiary: pinkLight,
    onTertiary: Color(0xFF660033),
    tertiaryContainer: pink,
    onTertiaryContainer: white,
    error: Color(0xFFF9DEDC),
    onError: Color(0xFF410E0B),
    errorContainer: Color(0xFF5F1811),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: Color(0xFF1A1A1A),
    onSurface: white,
    surfaceContainerHighest: Color(0xFF49454E),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454E),
    scrim: ink,
    inverseSurface: white,
    onInverseSurface: Color(0xFF313033),
    inversePrimary: pink,
    shadow: ink,
  );
}
