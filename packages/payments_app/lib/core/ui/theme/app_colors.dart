import 'package:flutter/material.dart';

/// The app's colour tokens. Read them with `AppColors.of(context)`.
///
/// Status colours differ in lightness as well as hue, and always come with a
/// text label, so colour is never the only signal.
@immutable
final class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.ground,
    required this.surface,
    required this.fill,
    required this.outline,
    required this.divider,
    required this.ink,
    required this.muted,
    required this.accent,
    required this.onAccent,
    required this.accentContainer,
    required this.onAccentContainer,
    required this.neutralButton,
    required this.disabled,
    required this.onDisabled,
    required this.success,
    required this.successContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
    required this.pending,
    required this.pendingContainer,
    required this.pendingBorder,
    required this.pendingBar,
    required this.badge,
    required this.scrim,
  });

  static const AppColors light = AppColors(
    ground: Color(0xFFF4F5F8),
    surface: Color(0xFFFFFFFF),
    fill: Color(0xFFF4F5F8),
    outline: Color(0xFFE6E8EE),
    divider: Color(0xFFEEF0F4),
    ink: Color(0xFF0F1115),
    muted: Color(0xFF5B6270),
    accent: Color(0xFF2F5BEA),
    onAccent: Color(0xFFFFFFFF),
    accentContainer: Color(0xFFE8EDFF),
    onAccentContainer: Color(0xFF2F4BC7),
    neutralButton: Color(0xFFEEF0F4),
    disabled: Color(0xFFE6E8EE),
    onDisabled: Color(0xFF6B7280),
    success: Color(0xFF0B6B3A),
    successContainer: Color(0xFFE2F5EC),
    danger: Color(0xFFB42318),
    dangerContainer: Color(0xFFFDECEA),
    onDangerContainer: Color(0xFF8C1C13),
    pending: Color(0xFF7A4F00),
    pendingContainer: Color(0xFFFFF1D6),
    pendingBorder: Color(0xFFF2C46B),
    pendingBar: Color(0xFFE3A42F),
    badge: Color(0xFFD92D20),
    scrim: Color(0x7A0F1115),
  );

  /// Page background.
  final Color ground;

  /// Cards, sheets, the tab bar.
  final Color surface;

  /// Inset areas inside a surface (e.g. the details block in a sheet).
  final Color fill;
  final Color outline;
  final Color divider;

  /// Primary text.
  final Color ink;

  /// Secondary text; 6.2:1 on [surface].
  final Color muted;

  final Color accent;
  final Color onAccent;
  final Color accentContainer;
  final Color onAccentContainer;
  final Color neutralButton;
  final Color disabled;
  final Color onDisabled;

  final Color success;
  final Color successContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  /// Waiting-on-you states: pending requests and expiry.
  final Color pending;
  final Color pendingContainer;
  final Color pendingBorder;
  final Color pendingBar;

  final Color badge;
  final Color scrim;

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ?? light;

  @override
  AppColors copyWith() => this;

  /// A single palette for now, so there is nothing to interpolate.
  @override
  AppColors lerp(covariant AppColors? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}
