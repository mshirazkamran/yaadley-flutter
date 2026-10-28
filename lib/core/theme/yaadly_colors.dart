import 'package:flutter/painting.dart';

/// Design tokens ported 1:1 from the Figma Make export (`design/figma-make/src/index.css`).
abstract final class YaadlyColors {
  static const cream = Color(0xFFFBF6EA); // app background
  static const paper = Color(0xFFFFFDF6); // cards, nav bar
  static const butter = Color(0xFFFFF1AD); // soft highlight
  static const sun = Color(0xFFF7C948); // primary / active
  static const sand = Color(0xFFECDCC0); // secondary surfaces
  static const tan = Color(0xFFCFB08A); // accents, waveform
  static const ink = Color(0xFF2D2113); // text, outlines, hard shadows
  static const clay = Color(0xFF7A6650); // muted text, labels
  static const rust = Color(0xFFB83D26); // errors, overdue, clashes
}

/// Spacing scale (px). Mirrors the Tailwind steps used in the design.
abstract final class YaadlySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const page = 20.0; // `px-5` horizontal page padding
}
