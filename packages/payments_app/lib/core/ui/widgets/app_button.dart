import 'package:flutter/material.dart';
import 'package:payments_app/core/ui/motion.dart';
import 'package:payments_app/core/ui/theme/app_colors.dart';
import 'package:payments_app/core/ui/theme/app_text.dart';

enum AppButtonVariant { primary, neutral, danger }

/// A full-height pill button with a loading state.
///
/// While [loading], it shows a spinner, ignores taps and keeps its size, so
/// the layout doesn't jump.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final enabled = onPressed != null && !loading;
    final (background, foreground) = switch (variant) {
      _ when onPressed == null && !loading => (
        colors.disabled,
        colors.onDisabled,
      ),
      AppButtonVariant.primary => (colors.accent, colors.onAccent),
      AppButtonVariant.neutral => (colors.neutralButton, colors.ink),
      AppButtonVariant.danger => (
        colors.dangerContainer,
        colors.danger,
      ),
    };

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, in progress' : label,
      excludeSemantics: true,
      child: SizedBox(
        height: 52,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            backgroundColor: background,
            disabledBackgroundColor: background,
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            textStyle: AppText.button(foreground),
          ),
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.fast),
            child: loading
                ? SizedBox.square(
                    key: const ValueKey('loading'),
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: foreground,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20, color: foreground),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.button(foreground),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
