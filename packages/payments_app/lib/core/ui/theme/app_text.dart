import 'package:flutter/widgets.dart';

abstract final class AppFonts {
  /// UI text.
  static const String sans = 'Manrope';

  /// Money, references and account numbers: equal-width digits line up.
  static const String mono = 'DMMono';
}

/// The type scale. Colour is passed in so styles stay theme-agnostic.
abstract final class AppText {
  static TextStyle title(Color color) =>
      _sans(28, FontWeight.w800, color, letterSpacing: -0.5);

  static TextStyle heading(Color color) =>
      _sans(24, FontWeight.w800, color, letterSpacing: -0.4);

  static TextStyle section(Color color) => _sans(18, FontWeight.w800, color);

  static TextStyle label(Color color) => _sans(15, FontWeight.w800, color);

  static TextStyle body(Color color) => _sans(15, FontWeight.w700, color);

  static TextStyle bodyMedium(Color color) => _sans(14, FontWeight.w700, color);

  static TextStyle caption(Color color) => _sans(13, FontWeight.w600, color);

  static TextStyle small(Color color) => _sans(12, FontWeight.w700, color);

  static TextStyle button(Color color) => _sans(16, FontWeight.w800, color);

  static TextStyle mono(double size, Color color) => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: size,
    fontWeight: FontWeight.w500,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle _sans(
    double size,
    FontWeight weight,
    Color color, {
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );
}
