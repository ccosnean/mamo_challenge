import 'package:flutter/widgets.dart';

/// Durations and curves, all collapsing to zero when the user has asked the
/// system to reduce motion.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);

  static const Curve standard = Curves.easeOutCubic;

  /// [duration], or zero when animations are disabled.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
      ? Duration.zero
      : duration;
}
