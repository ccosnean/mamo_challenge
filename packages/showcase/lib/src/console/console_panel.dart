import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:payments_app/payments_app.dart';
import 'package:showcase/src/console/console_log.dart';
import 'package:showcase/src/ui/panel.dart';

/// Live logs from the app and the mock bank, as the app's logger emits them
/// (redacted in release builds). Filter by source; follows new lines unless
/// scrolled up.
class ConsolePanel extends StatefulWidget {
  const ConsolePanel({
    required this.log,
    required this.onToggle,
    this.expanded = true,
    super.key,
  });

  final ConsoleLog log;

  /// Collapsed, only the header bar shows.
  final bool expanded;

  final VoidCallback onToggle;

  @override
  State<ConsolePanel> createState() => _ConsolePanelState();
}

class _ConsolePanelState extends State<ConsolePanel> {
  final ScrollController _scroll = ScrollController();
  final Set<LogSource> _sources = LogSource.values.toSet();
  bool _debug = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool get _atBottom =>
      !_scroll.hasClients ||
      _scroll.position.pixels >= _scroll.position.maxScrollExtent - 24;

  void _followIfAtBottom() {
    if (!_atBottom) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A Material, so the buttons and chips inside show their ink.
    return Material(
      color: Workbench.panel,
      shape: const Border(top: BorderSide(color: Workbench.border)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            child: Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  size: 18,
                  color: Workbench.accent,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Console',
                  style: TextStyle(
                    color: Workbench.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<List<LogEntry>>(
                  valueListenable: widget.log.entries,
                  builder: (context, entries, _) => Text(
                    '${entries.length}',
                    style: Workbench.monoStyle(12, Workbench.muted),
                  ),
                ),
                const Spacer(),
                if (widget.expanded)
                  IconButton(
                    tooltip: 'Clear',
                    onPressed: widget.log.clear,
                    icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  ),
                IconButton(
                  tooltip: widget.expanded ? 'Collapse' : 'Expand',
                  onPressed: widget.onToggle,
                  icon: Icon(
                    widget.expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                  ),
                ),
              ],
            ),
          ),
          if (widget.expanded)
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final source in LogSource.values)
                    _Filter(
                      label: source.label,
                      selected: _sources.contains(source),
                      onSelected: (on) => setState(
                        () =>
                            on ? _sources.add(source) : _sources.remove(source),
                      ),
                    ),
                  _Filter(
                    label: 'Debug',
                    selected: _debug,
                    onSelected: (on) => setState(() => _debug = on),
                  ),
                ],
              ),
            ),
          if (widget.expanded) ...[
            const Divider(height: 1),
            Expanded(
              child: ValueListenableBuilder<List<LogEntry>>(
                valueListenable: widget.log.entries,
                builder: (context, entries, _) {
                  final visible = entries
                      .where(
                        (e) =>
                            _sources.contains(LogSource.of(e)) &&
                            (_debug || e.level >= Level.INFO),
                      )
                      .toList();
                  _followIfAtBottom();
                  return SelectionArea(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: visible.length,
                      itemBuilder: (context, index) =>
                          _Line(entry: visible[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// On: accent outline and bright label. Off: muted.
class _Filter extends StatelessWidget {
  const _Filter({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: selected ? Workbench.text : Workbench.muted,
      ),
      backgroundColor: Workbench.panel,
      selectedColor: Workbench.raised,
      side: BorderSide(color: selected ? Workbench.accent : Workbench.border),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.entry});

  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final level = entry.level;
    final (tag, color) = level >= Level.SEVERE
        ? ('E', Workbench.bad)
        : level >= Level.WARNING
        ? ('W', Workbench.warn)
        : level >= Level.INFO
        ? ('I', Workbench.good)
        : ('D', Workbench.muted);
    final source = LogSource.of(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Text.rich(
        TextSpan(
          style: Workbench.monoStyle(12, Workbench.text),
          children: [
            TextSpan(
              text: '${_time(entry.time)} ',
              style: const TextStyle(color: Workbench.muted),
            ),
            TextSpan(
              text: '$tag ',
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: '${source.label.padRight(4)} ',
              style: const TextStyle(color: Workbench.accent),
            ),
            TextSpan(
              text: '${entry.logger}  ',
              style: const TextStyle(color: Workbench.muted),
            ),
            TextSpan(text: entry.message),
            if (entry.error != null)
              TextSpan(
                text: '  ↳ ${entry.error}',
                style: TextStyle(color: color),
              ),
          ],
        ),
      ),
    );
  }

  static String _time(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}:${two(time.second)}.'
        '${time.millisecond.toString().padLeft(3, '0')}';
  }
}
