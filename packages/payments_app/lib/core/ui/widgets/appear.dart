import 'package:flutter/material.dart';
import 'package:payments_app/core/ui/motion.dart';

/// Grows, fades and slides its child in once, when [animate] is true on
/// first build. Used for list items that just arrived (a new payment at the
/// top of the list), not for items that were already there.
class Appear extends StatefulWidget {
  const Appear({required this.child, this.animate = true, super.key});

  final Widget child;
  final bool animate;

  @override
  State<Appear> createState() => _AppearState();
}

class _AppearState extends State<Appear> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.slow,
    value: widget.animate ? 0 : 1,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.standard,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.value < 1 && !_controller.isAnimating) {
      _controller.duration = Motion.of(context, Motion.slow);
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -0.15),
            end: Offset.zero,
          ).animate(_curve),
          child: widget.child,
        ),
      ),
    );
  }
}
