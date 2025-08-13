import 'package:flutter/material.dart';

class AppTokens {
  // Spacing
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;

  // Radius
  static const r4 = 4.0;
  static const r8 = 8.0;
  static const r12 = 12.0;
  static const r16 = 16.0;

  // Durations
  static const dFast = Duration(milliseconds: 120);
  static const dMed = Duration(milliseconds: 220);
  static const dPage = Duration(milliseconds: 320);

  // Elevation (semantic)
  static const elevCard = 1.0;
  static const elevHover = 3.0;

  // Breakpoints
  static const bpMobile = 600.0;
  static const bpTablet = 1000.0;
  static const bpWide = 1400.0;

  // Shadows (custom subtle)
  static List<BoxShadow> shadowCard(Color c) => [
    BoxShadow(
      color: c.withOpacity(.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
