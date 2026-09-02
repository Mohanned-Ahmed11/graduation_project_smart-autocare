import 'package:flutter/material.dart';

class ScaleTap extends StatefulWidget {
  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.minScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1, end: widget.minScale).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
