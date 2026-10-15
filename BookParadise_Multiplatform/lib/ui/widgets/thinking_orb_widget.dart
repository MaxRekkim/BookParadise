import 'dart:math' as math;
import 'package:flutter/material.dart';

enum OrbState {
  idle,
  breathing,
  listening,
  thinking,
  complete,
}

class ThinkingOrbWidget extends StatefulWidget {
  final OrbState state;
  final double size;
  final Color? color;

  const ThinkingOrbWidget({
    super.key,
    this.state = OrbState.breathing,
    this.size = 140.0,
    this.color,
  });

  @override
  State<ThinkingOrbWidget> createState() => _ThinkingOrbWidgetState();
}

class _ThinkingOrbWidgetState extends State<ThinkingOrbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orbColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _OrbPainter(
            progress: _controller.value,
            color: orbColor,
            state: widget.state,
          ),
        );
      },
    );
  }
}

class _OrbPainter extends CustomPainter {
  final double progress;
  final Color color;
  final OrbState state;

  _OrbPainter({
    required this.progress,
    required this.color,
    required this.state,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Background soft glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.35),
          color.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, glowPaint);

    // Inner pulsing concentric rings
    final pulse = math.sin(progress * 2 * math.pi);
    final coreRadius = maxRadius * (0.55 + 0.12 * pulse);

    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.95),
          color.withOpacity(0.65),
          color.withOpacity(0.1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: coreRadius));

    canvas.drawCircle(center, coreRadius, corePaint);

    // Dynamic orbital dots
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.85);
    const numDots = 8;
    for (int i = 0; i < numDots; i++) {
      final angle = (i * 2 * math.pi / numDots) + (progress * 2 * math.pi);
      final r = coreRadius * (0.85 + 0.15 * math.cos(angle * 2));
      final dx = center.dx + r * math.cos(angle);
      final dy = center.dy + r * math.sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter oldDelegate) => true;
}
