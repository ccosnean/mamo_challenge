import 'package:flutter/material.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const colors = AppColors.light;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.accent,
        ).copyWith(
          primary: colors.accent,
          onPrimary: colors.onAccent,
          surface: colors.surface,
          onSurface: colors.ink,
          onSurfaceVariant: colors.muted,
          error: colors.danger,
          outline: colors.outline,
          outlineVariant: colors.divider,
          scrim: colors.scrim,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.sans,
      scaffoldBackgroundColor: colors.ground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: const [colors],
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppText.small(colors.ink).copyWith(fontWeight: FontWeight.w800)
              : AppText.small(colors.muted),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? colors.ink
                : colors.muted,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: colors.scrim,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: colors.badge,
        textColor: Colors.white,
        textStyle: AppText.small(Colors.white).copyWith(fontSize: 10),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.accent,
      ),
    );
  }
}
