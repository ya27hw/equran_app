import 'package:flutter/material.dart';

/// Fades and gently lifts [child] into place once when it first appears.
///
/// Give it a [ValueKey] that changes whenever the content is swapped (for
/// example the selected tab index) so the entrance replays. The animation is
/// short, plays a single time and is skipped when the platform asks to reduce
/// motion.
class TabEntrance extends StatefulWidget {
  const TabEntrance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 240),
    this.offset = 0.012,
  });

  final Widget child;
  final Duration duration;

  /// Vertical travel as a fraction of the child's height.
  final double offset;

  @override
  State<TabEntrance> createState() => _TabEntranceState();
}

class _TabEntranceState extends State<TabEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offset),
    end: Offset.zero,
  ).animate(_curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
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
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
