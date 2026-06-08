import 'package:flutter/material.dart';
import 'app_colors.dart';

// Uso: context.dc.surface  /  context.dc.ink  /  etc.
extension DashColorsX on BuildContext {
  DashColors get dc =>
      DashColors(Theme.of(this).brightness == Brightness.dark);
}

class DashColors {
  const DashColors(this.dark);
  final bool dark;

  // ── Fondos ───────────────────────────────────────────────────────────────
  /// Fondo del scaffold / página
  Color get bg => dark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F4);

  /// Superficies de tarjeta / panel
  Color get surface => dark ? const Color(0xFF1C1C1E) : AppColors.white;

  /// Superficie ligeramente elevada (inputs, chips dentro de cards)
  Color get elevated => dark ? const Color(0xFF2C2C2E) : AppColors.fieldBg;

  // ── Texto ─────────────────────────────────────────────────────────────────
  Color get ink => dark ? const Color(0xFFF5F5F3) : AppColors.ink;
  Color get ink2 => dark ? const Color(0xFF9D9D9A) : AppColors.ink2;
  Color get ink3 => dark ? const Color(0xFF636360) : AppColors.ink3;

  // ── Estructura ────────────────────────────────────────────────────────────
  Color get divider => dark ? const Color(0xFF2C2C2E) : AppColors.progressBg;
  Color get shimmerBase =>
      dark ? const Color(0xFF2C2C2E) : AppColors.shimmerBase;
  Color get shimmerLight =>
      dark ? const Color(0xFF3A3A3C) : AppColors.shimmerLight;
  Color get progressBg =>
      dark ? const Color(0xFF2C2C2E) : AppColors.progressBg;
  Color get progressFill =>
      dark ? const Color(0xFF636360) : AppColors.progressFill;

  /// Chip / segment seleccionado dentro de un surface
  Color get chipSelected =>
      dark ? const Color(0xFF3A3A3C) : AppColors.progressBg;

  /// Fondo del input / buscador
  Color get input => dark ? const Color(0xFF1C1C1E) : AppColors.white;

  /// Hint / icono en inputs
  Color get hint => dark ? const Color(0xFF636360) : AppColors.ink3;
}
