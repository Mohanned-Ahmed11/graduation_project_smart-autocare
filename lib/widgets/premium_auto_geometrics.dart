import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';

/// Full-screen subtle geometric motifs: wheels, chassis line, road dashes, hex “bolt”.
/// Sits behind content; use inside a [Stack] with [IgnorePointer].
class PremiumAutoGeometrics extends StatefulWidget {
  const PremiumAutoGeometrics({
    super.key,
    this.intensity = 1,
  });

  /// 0–1 scales overall opacity.
  final double intensity;

  @override
  State<PremiumAutoGeometrics> createState() => _PremiumAutoGeometricsState();
}

class _PremiumAutoGeometricsState extends State<PremiumAutoGeometrics>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return CustomPaint(
          painter: _AutoGeometricPainter(
            t: _c.value,
            isDark: isDark,
            intensity: widget.intensity.clamp(0.0, 1.0),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AutoGeometricPainter extends CustomPainter {
  _AutoGeometricPainter({
    required this.t,
    required this.isDark,
    required this.intensity,
  });

  final double t;
  final bool isDark;
  final double intensity;

  Color _c(Color base, double a) => base.withValues(alpha: a * intensity);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final primary = AppColors.primary;
    final secondary = AppColors.secondary;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // — Road lane dashes (bottom band, scroll horizontally)
    final dashY = h * 0.88;
    final dashW = 22.0;
    final gap = 14.0;
    final scroll = (t * 80) % (dashW + gap);
    stroke.color = _c(primary, isDark ? 0.14 : 0.18);
    for (double x = -scroll; x < w + dashW; x += dashW + gap) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, dashY, dashW, 3),
          const Radius.circular(2),
        ),
        Paint()..color = _c(primary, isDark ? 0.12 : 0.16),
      );
    }

    // — Abstract “chassis” trapezoid (upper-mid)
    final bodyPath = Path()
      ..moveTo(w * 0.18, h * 0.42)
      ..lineTo(w * 0.82, h * 0.38)
      ..lineTo(w * 0.76, h * 0.52)
      ..lineTo(w * 0.22, h * 0.54)
      ..close();
    stroke.color = _c(secondary, isDark ? 0.2 : 0.14);
    stroke.strokeWidth = 1.8;
    canvas.drawPath(bodyPath, stroke);

    // — Wheels with rotating spokes
    final spin = t * math.pi * 2;
    _wheel(canvas, Offset(w * 0.32, h * 0.56), 26, spin, primary);
    _wheel(canvas, Offset(w * 0.68, h * 0.54), 30, -spin * 1.1, primary);

    // — Hex “fastener” top-right (slow rotation)
    canvas.save();
    canvas.translate(w * 0.88, h * 0.14);
    canvas.rotate(t * math.pi * 0.4);
    _hexagon(canvas, 18, _c(primary, isDark ? 0.22 : 0.2));
    canvas.restore();

    // — Second hex bottom-left
    canvas.save();
    canvas.translate(w * 0.1, h * 0.72);
    canvas.rotate(-t * math.pi * 0.35);
    _hexagon(canvas, 14, _c(secondary, isDark ? 0.18 : 0.12));
    canvas.restore();

    // — Motion chevrons (right side)
    stroke.color = _c(primary, isDark ? 0.12 : 0.1);
    stroke.strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      final ox = w * 0.92 - i * 16 + (math.sin(t * math.pi * 2 + i) * 4);
      final oy = h * 0.28 + i * 28.0;
      final p = Path()
        ..moveTo(ox, oy + 10)
        ..lineTo(ox - 12, oy)
        ..lineTo(ox, oy - 10);
      canvas.drawPath(p, stroke);
    }

    // — Diagonal grid hints (very subtle)
    stroke.color = _c(primary, isDark ? 0.04 : 0.05);
    stroke.strokeWidth = 1;
    for (var i = -2; i < 8; i++) {
      final off = (t * 40 + i * 55) % 200;
      canvas.drawLine(
        Offset(off, 0),
        Offset(off + h * 0.35, h * 0.35),
        stroke,
      );
    }
  }

  void _wheel(Canvas canvas, Offset center, double r, double spin, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spin);
    final ring = Paint()
      ..color = _c(color, isDark ? 0.28 : 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(Offset.zero, r, ring);
    final spoke = Paint()
      ..color = _c(color, isDark ? 0.2 : 0.16)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      canvas.drawLine(Offset.zero, Offset(0, -r * 0.92), spoke);
      canvas.rotate(math.pi / 3);
    }
    canvas.restore();
  }

  void _hexagon(Canvas canvas, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 - math.pi / 2;
      final x = math.cos(a) * radius;
      final y = math.sin(a) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    final fill = Paint()
      ..color = color.withValues(alpha: color.a * 0.15)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _AutoGeometricPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.isDark != isDark ||
        oldDelegate.intensity != intensity;
  }
}

/// Extra floating polygons + rings for hero screens (onboarding / auth).
class FloatingAutoShapeAccents extends StatelessWidget {
  const FloatingAutoShapeAccents({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final p = AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.4);
    final s = AppColors.secondary.withValues(alpha: isDark ? 0.28 : 0.22);

    Widget diamond(Color c, double size) {
      return CustomPaint(
        size: Size(size, size),
        painter: _DiamondPainter(color: c),
      );
    }

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.12,
            left: 24,
            child: diamond(p, 36)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: -10, end: 10, duration: 3500.ms, curve: Curves.easeInOut)
                .rotate(begin: -0.08, end: 0.08, duration: 4000.ms, curve: Curves.easeInOut),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.22,
            right: 32,
            child: _GearOutline(size: 44, color: s)
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 12000.ms, begin: 0, end: 1),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height * 0.24,
            left: 40,
            child: _RingPulse(size: 52, color: p)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.08, 1.08),
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            bottom: MediaQuery.sizeOf(context).height * 0.18,
            right: 20,
            child: diamond(s, 28)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveX(begin: -8, end: 8, duration: 2800.ms, curve: Curves.easeInOut)
                .fadeIn(duration: 600.ms),
          ),
          Positioned(
            top: MediaQuery.sizeOf(context).height * 0.45,
            left: 12,
            child: _ParallelogramSpeed(color: p.withValues(alpha: 0.5))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .slideX(begin: -0.03, end: 0.03, duration: 2400.ms, curve: Curves.easeInOut),
          ),
        ],
      ),
    );
  }
}

class _DiamondPainter extends CustomPainter {
  _DiamondPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  @override
  bool shouldRepaint(covariant _DiamondPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _GearOutline extends StatelessWidget {
  const _GearOutline({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GearPainter(color: color),
    );
  }
}

class _GearPainter extends CustomPainter {
  _GearPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.38;
    final path = Path();
    const teeth = 8;
    for (var i = 0; i < teeth; i++) {
      final a0 = (i / teeth) * math.pi * 2 - math.pi / 2;
      final a1 = a0 + math.pi / teeth * 0.45;
      final a2 = a0 + math.pi / teeth * 0.55;
      final a3 = a0 + math.pi / teeth;
      final ir = r * 0.55;
      final or = r;
      if (i == 0) {
        path.moveTo(
          c.dx + math.cos(a0) * ir,
          c.dy + math.sin(a0) * ir,
        );
      }
      path.lineTo(c.dx + math.cos(a1) * or, c.dy + math.sin(a1) * or);
      path.lineTo(c.dx + math.cos(a2) * or, c.dy + math.sin(a2) * or);
      path.lineTo(c.dx + math.cos(a3) * ir, c.dy + math.sin(a3) * ir);
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawCircle(c, r * 0.28, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _GearPainter oldDelegate) => color != oldDelegate.color;
}

class _RingPulse extends StatelessWidget {
  const _RingPulse({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _RingPainter(color: color),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final inner = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(c, size.width * 0.42, outer);
    canvas.drawCircle(c, size.width * 0.28, inner);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => color != oldDelegate.color;
}

class _ParallelogramSpeed extends StatelessWidget {
  const _ParallelogramSpeed({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(48, 24),
      painter: _ParaPainter(color: color),
    );
  }
}

class _ParaPainter extends CustomPainter {
  _ParaPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final skew = 10.0;
    final path = Path()
      ..moveTo(skew, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - skew, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.15)..style = PaintingStyle.fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  @override
  bool shouldRepaint(covariant _ParaPainter oldDelegate) => color != oldDelegate.color;
}

/// Full-screen animated geometry tuned for login / sign-up (corners, triangles, dashes).
/// Use behind [FloatingAutoShapeAccents]; complements app-wide [PremiumAutoGeometrics].
class AuthGeometricMotionLayer extends StatefulWidget {
  const AuthGeometricMotionLayer({super.key, this.intensity = 1});

  final double intensity;

  @override
  State<AuthGeometricMotionLayer> createState() => _AuthGeometricMotionLayerState();
}

class _AuthGeometricMotionLayerState extends State<AuthGeometricMotionLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        return CustomPaint(
          painter: _AuthMotionPainter(
            t: _c.value,
            isDark: isDark,
            intensity: widget.intensity.clamp(0.0, 1.0),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _AuthMotionPainter extends CustomPainter {
  _AuthMotionPainter({
    required this.t,
    required this.isDark,
    required this.intensity,
  });

  final double t;
  final bool isDark;
  final double intensity;

  Color _mix(Color base, double a) => base.withValues(alpha: a * intensity);

  void _triangleOutline(Canvas canvas, double r, Color color) {
    final path = Path();
    for (var i = 0; i < 3; i++) {
      final ang = -math.pi / 2 + i * math.pi * 2 / 3;
      final x = math.cos(ang) * r;
      final y = math.sin(ang) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: color.a * 0.14)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.35,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final primary = AppColors.primary;
    final secondary = AppColors.secondary;

    final pulse = 0.62 + 0.38 * math.sin(t * math.pi * 2);
    final bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.45
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _mix(primary, (isDark ? 0.2 : 0.15) * pulse);

    const L = 34.0;
    const inset = 14.0;

    void strokePath(Path path) => canvas.drawPath(path, bracket);

    // Top-left
    strokePath(Path()
      ..moveTo(inset, inset + L)
      ..lineTo(inset, inset)
      ..lineTo(inset + L, inset));
    // Top-right
    strokePath(Path()
      ..moveTo(w - inset, inset + L)
      ..lineTo(w - inset, inset)
      ..lineTo(w - inset - L, inset));
    // Bottom-left
    strokePath(Path()
      ..moveTo(inset, h - inset - L)
      ..lineTo(inset, h - inset)
      ..lineTo(inset + L, h - inset));
    // Bottom-right
    strokePath(Path()
      ..moveTo(w - inset, h - inset - L)
      ..lineTo(w - inset, h - inset)
      ..lineTo(w - inset - L, h - inset));

    // Rotating triangle — upper right
    canvas.save();
    canvas.translate(w * 0.76, h * 0.26);
    canvas.rotate(t * math.pi * 0.55);
    _triangleOutline(canvas, 20, _mix(secondary, isDark ? 0.24 : 0.2));
    canvas.restore();

    // Counter-rotating triangle — lower left
    canvas.save();
    canvas.translate(w * 0.12, h * 0.68);
    canvas.rotate(-t * math.pi * 0.7);
    _triangleOutline(canvas, 17, _mix(primary, isDark ? 0.22 : 0.17));
    canvas.restore();

    // Rounded square frame — left mid
    canvas.save();
    canvas.translate(w * 0.1, h * 0.48);
    canvas.rotate(t * math.pi * 0.4);
    final rr = 13.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: rr * 2, height: rr * 2),
        const Radius.circular(4),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.25
        ..color = _mix(primary, isDark ? 0.18 : 0.13),
    );
    canvas.restore();

    // Drifting chevron dashes (right column)
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = _mix(secondary, isDark ? 0.12 : 0.1);

    final drift = t * 90;
    for (var i = 0; i < 7; i++) {
      final y = (h * 0.12 + i * 48 + drift) % (h * 0.72) + h * 0.08;
      final ox = w * 0.86 + math.sin(t * math.pi * 2 + i * 0.7) * 10;
      final p = Path()
        ..moveTo(ox, y + 8)
        ..lineTo(ox - 11, y)
        ..lineTo(ox, y - 8);
      canvas.drawPath(p, dash);
    }

    // Sweeping arc — right edge
    canvas.drawArc(
      Rect.fromCenter(center: Offset(w - 28, h * 0.52), width: 72, height: 72),
      t * math.pi * 2 * 0.85,
      math.pi * 0.5,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = _mix(primary, isDark ? 0.14 : 0.11),
    );

    // Mid horizontal scan dashes
    final scanY = h * 0.38 + math.sin(t * math.pi * 2) * 18;
    final scan = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = _mix(primary, isDark ? 0.08 : 0.07);
    final phase = (t * 140) % 40;
    for (double x = -phase; x < w; x += 40) {
      canvas.drawLine(Offset(x, scanY), Offset(x + 18, scanY), scan);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthMotionPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.isDark != isDark || oldDelegate.intensity != intensity;
}

/// Decorative line + rotated squares for auth headers.
class AuthGeometricDivider extends StatelessWidget {
  const AuthGeometricDivider({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(height: 1, thickness: 1, color: color.withValues(alpha: 0.25))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              3,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.rotate(
                  angle: i * 0.52,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.55 - i * 0.12),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: Divider(height: 1, thickness: 1, color: color.withValues(alpha: 0.25))),
      ],
    );
  }
}

/// Wraps [child] with geometric backdrop + optional corner accents.
class PremiumAutoScreenWrap extends StatelessWidget {
  const PremiumAutoScreenWrap({
    super.key,
    required this.child,
    this.showFloatingAccents = false,
    this.geometryIntensity = 0.85,
  });

  final Widget child;
  final bool showFloatingAccents;
  final double geometryIntensity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: PremiumAutoGeometrics(intensity: geometryIntensity),
          ),
        ),
        if (showFloatingAccents) const FloatingAutoShapeAccents(),
        child,
      ],
    );
  }
}
