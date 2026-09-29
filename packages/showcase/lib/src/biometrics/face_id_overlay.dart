import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:showcase/src/biometrics/biometrics_simulator.dart';

/// What the phone's OS draws over the app during Face ID: the Dynamic
/// Island grows into a small panel that scans, then shows a check or a
/// cross. It lives outside the app, on the device's screen, and takes no
/// input, like the real one.
class FaceIdOverlay extends StatelessWidget {
  const FaceIdOverlay({
    required this.biometrics,
    required this.child,
    super.key,
  });

  final BiometricsSimulator biometrics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        // Grows out of the Dynamic Island: same black, so the two merge,
        // the way iOS runs Face ID in the island.
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<FaceIdPhase?>(
            valueListenable: biometrics.phase,
            builder: (context, phase, _) => IgnorePointer(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => ScaleTransition(
                    alignment: Alignment.topCenter,
                    scale: Tween<double>(begin: 0.4, end: 1).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: phase == null
                      ? const SizedBox.shrink()
                      : _Hud(key: const ValueKey('hud'), phase: phase),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.phase, super.key});

  final FaceIdPhase phase;

  @override
  Widget build(BuildContext context) {
    final label = switch (phase) {
      FaceIdPhase.scanning => 'Face ID',
      FaceIdPhase.succeeded => 'Face ID',
      FaceIdPhase.failed => 'Not Recognised',
    };

    return Semantics(
      liveRegion: true,
      label: switch (phase) {
        FaceIdPhase.scanning => 'Face ID scanning',
        FaceIdPhase.succeeded => 'Face ID recognised',
        FaceIdPhase.failed => 'Face ID not recognised',
      },
      excludeSemantics: true,
      child: Container(
        width: 190,
        padding: const EdgeInsets.fromLTRB(16, 46, 16, 16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 64,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween<double>(begin: 0.6, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: switch (phase) {
                  FaceIdPhase.scanning => const _Scanning(
                    key: ValueKey('scan'),
                  ),
                  FaceIdPhase.succeeded => const Icon(
                    Icons.check_circle_outline_rounded,
                    key: ValueKey('ok'),
                    size: 64,
                    color: Color(0xFF30D158),
                  ),
                  FaceIdPhase.failed => const _Shake(
                    key: ValueKey('fail'),
                    child: Icon(
                      Icons.highlight_off_rounded,
                      size: 64,
                      color: Color(0xFFFF453A),
                    ),
                  ),
                },
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The face glyph, breathing while the "scan" runs.
class _Scanning extends StatefulWidget {
  const _Scanning({super.key});

  @override
  State<_Scanning> createState() => _ScanningState();
}

class _ScanningState extends State<_Scanning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.05).animate(_pulse),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.6, end: 1).animate(_pulse),
        child: const Icon(Icons.face_outlined, size: 64, color: Colors.white),
      ),
    );
  }
}

/// A short horizontal shake, as when Face ID doesn't recognise you.
class _Shake extends StatefulWidget {
  const _Shake({required this.child, super.key});

  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final offset = math.sin(t * math.pi * 6) * 10 * (1 - t);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
