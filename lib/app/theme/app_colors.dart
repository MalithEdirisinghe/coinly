import 'package:flutter/material.dart';

@immutable
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.primary,
    required this.primaryLight,
    required this.accent,
    required this.accentDark,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.error,
    required this.warning,
    required this.successBackground,
    required this.successBorder,
    required this.errorBackground,
    required this.errorBorder,
    required this.shadow,
  });

  final Color primary;
  final Color primaryLight;
  final Color accent;
  final Color accentDark;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;
  final Color warning;
  final Color successBackground;
  final Color successBorder;
  final Color errorBackground;
  final Color errorBorder;
  final Color shadow;

  static const light = AppThemeColors(
    primary: Color(0xFF1E3A5F),
    primaryLight: Color(0xFF2A4A73),
    accent: Color(0xFF10B981),
    accentDark: Color(0xFF059669),
    background: Color(0xFFF8FAFC),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF64748B),
    error: Color(0xFFEF4444),
    warning: Color(0xFFF59E0B),
    successBackground: Color(0xFFEAF8F2),
    successBorder: Color(0xFFBEE9D3),
    errorBackground: Color(0xFFFDEEEE),
    errorBorder: Color(0xFFF6CACA),
    shadow: Color(0x1A0F172A),
  );

  static const dark = AppThemeColors(
    primary: Color(0xFF163055),
    primaryLight: Color(0xFF23477B),
    accent: Color(0xFF34D399),
    accentDark: Color(0xFF10B981),
    background: Color(0xFF011739),
    surface: Color(0xFF07224B),
    surfaceMuted: Color(0xFF0B2C5E),
    border: Color(0xFF153A70),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF9DB0D0),
    error: Color(0xFFFF6B6B),
    warning: Color(0xFFFBBF24),
    successBackground: Color(0xFF0C2F33),
    successBorder: Color(0xFF166A58),
    errorBackground: Color(0xFF3A1820),
    errorBorder: Color(0xFF7F2B38),
    shadow: Color(0x52000000),
  );

  @override
  AppThemeColors copyWith({
    Color? primary,
    Color? primaryLight,
    Color? accent,
    Color? accentDark,
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? error,
    Color? warning,
    Color? successBackground,
    Color? successBorder,
    Color? errorBackground,
    Color? errorBorder,
    Color? shadow,
  }) {
    return AppThemeColors(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      successBackground: successBackground ?? this.successBackground,
      successBorder: successBorder ?? this.successBorder,
      errorBackground: errorBackground ?? this.errorBackground,
      errorBorder: errorBorder ?? this.errorBorder,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) {
      return this;
    }

    return AppThemeColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      successBackground: Color.lerp(
        successBackground,
        other.successBackground,
        t,
      )!,
      successBorder: Color.lerp(successBorder, other.successBorder, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      errorBorder: Color.lerp(errorBorder, other.errorBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppThemeColorsContext on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.light;
}
