import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'yaadly_colors.dart';

/// Typography from the design: Space Grotesk for display text, Geist for body text.
abstract final class YaadlyText {
  static TextStyle display({double size = 34, FontWeight weight = FontWeight.w700, Color color = YaadlyColors.ink}) =>
      GoogleFonts.spaceGrotesk(fontSize: size, fontWeight: weight, color: color, height: 1.02, letterSpacing: -0.02 * size);

  static TextStyle body({double size = 15, FontWeight weight = FontWeight.w400, Color color = YaadlyColors.ink}) =>
      GoogleFonts.geist(fontSize: size, fontWeight: weight, color: color, height: 1.35);

  /// `.label-caps`: small, spaced, uppercase kicker labels.
  static TextStyle labelCaps({Color color = YaadlyColors.clay}) =>
      GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.54, color: color);
}

ThemeData buildYaadlyTheme() {
  final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
  final textTheme = GoogleFonts.geistTextTheme(base.textTheme).apply(
    bodyColor: YaadlyColors.ink,
    displayColor: YaadlyColors.ink,
  );

  return base.copyWith(
    scaffoldBackgroundColor: YaadlyColors.cream,
    colorScheme: const ColorScheme.light(
      primary: YaadlyColors.sun,
      onPrimary: YaadlyColors.ink,
      secondary: YaadlyColors.sand,
      onSecondary: YaadlyColors.ink,
      surface: YaadlyColors.paper,
      onSurface: YaadlyColors.ink,
      error: YaadlyColors.rust,
      onError: YaadlyColors.paper,
      outline: YaadlyColors.ink,
    ),
    textTheme: textTheme.copyWith(
      headlineLarge: YaadlyText.display(),
      headlineMedium: YaadlyText.display(size: 24),
      titleLarge: YaadlyText.display(size: 20, weight: FontWeight.w600),
      labelSmall: YaadlyText.labelCaps(),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: YaadlyColors.ink,
      contentTextStyle: YaadlyText.body(color: YaadlyColors.butter, weight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
