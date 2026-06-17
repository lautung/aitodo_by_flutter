import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

class AppRadii {
  const AppRadii._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

class AppBreakpoints {
  const AppBreakpoints._();

  static const double compactMaxWidth = 560;
  static const double contentMaxWidth = 720;
  static const double wideContentMaxWidth = 960;
}

class AppInsets {
  const AppInsets._();

  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
  static const EdgeInsets surface = EdgeInsets.all(AppSpacing.lg);
  static const EdgeInsets compactSurface = EdgeInsets.all(AppSpacing.md);
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
}
