import 'package:flutter/material.dart';

/// The showcase's own palette: a dark workbench, deliberately unlike the
/// app, so it's always clear what is the product and what is tooling.
abstract final class Workbench {
  static const Color background = Color(0xFF0B0D10);
  static const Color panel = Color(0xFF14171C);
  static const Color raised = Color(0xFF1C2027);
  static const Color border = Color(0xFF262B33);
  static const Color text = Color(0xFFE6E8EE);
  static const Color muted = Color(0xFF9097A3);
  static const Color accent = Color(0xFF7C95FF);
  static const Color good = Color(0xFF4CC38A);
  static const Color warn = Color(0xFFE8B04B);
  static const Color bad = Color(0xFFF07167);

  static const String sans = 'Manrope';
  static const String mono = 'DMMono';

  static ThemeData theme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: sans,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: panel,
      onSurface: text,
      outline: border,
      error: bad,
    ),
    dividerColor: border,
    sliderTheme: const SliderThemeData(
      showValueIndicator: ShowValueIndicator.never,
    ),
  );

  static TextStyle monoStyle(double size, Color color) => TextStyle(
    fontFamily: mono,
    fontSize: size,
    color: color,
    fontWeight: FontWeight.w500,
  );
}

/// A titled module card.
class Panel extends StatelessWidget {
  const Panel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // A Material, not a DecoratedBox: list tiles and buttons inside draw
    // their ink on it.
    return Material(
      color: Workbench.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Workbench.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: Workbench.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Workbench.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Workbench.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

/// A compact action button for panels.
class PanelButton extends StatelessWidget {
  const PanelButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = false,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive
        ? Workbench.bad
        : primary
        ? Workbench.background
        : Workbench.text;
    return FilledButton.icon(
      onPressed: onPressed,
      icon: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: primary ? Workbench.accent : Workbench.raised,
        foregroundColor: foreground,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: Workbench.sans,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// `label ······ value` row.
class StatRow extends StatelessWidget {
  const StatRow({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Workbench.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(value, style: Workbench.monoStyle(13, Workbench.text)),
        ],
      ),
    );
  }
}
