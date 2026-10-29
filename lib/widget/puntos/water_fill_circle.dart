import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/app_colors.dart';

/// Círculo que se llena como agua según [progress] (0..1).
/// El nivel sube con animación y la superficie ondula de forma continua.
/// El número se dibuja dos veces: con el color normal sobre el fondo y en
/// blanco recortado sobre el agua, así siempre se lee bien (claro y oscuro).
class WaterFillCircle extends StatefulWidget {
  const WaterFillCircle({
    super.key,
    required this.progress,
    this.size = 200,
    this.valueText,
    this.captionText,
    this.waterColor,
    this.trackColor,
    this.borderColor,
    this.labelColor,
    this.semanticLabel,
  });

  final double progress;
  final double size;
  final String? valueText;
  final String? captionText;
  final Color? waterColor;
  final Color? trackColor;
  final Color? borderColor;
  final Color? labelColor;
  final String? semanticLabel;

  @override
  State<WaterFillCircle> createState() => _WaterFillCircleState();
}

class _WaterFillCircleState extends State<WaterFillCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeta "reducir animaciones" del sistema.
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final water = widget.waterColor ?? AppColors.primaryLight;

    return Semantics(
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.progress.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1400),
            curve: Curves.easeOutCubic,
            builder: (context, level, _) => AnimatedBuilder(
              animation: _wave,
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: _WaterPainter(
                  level: level,
                  phase: _wave.value * 2 * math.pi,
                  water: water,
                  track:
                      widget.trackColor ??
                      scheme.onSurface.withValues(alpha: 0.06),
                  border:
                      widget.borderColor ?? water.withValues(alpha: 0.7),
                  label: widget.labelColor ?? scheme.onSurface,
                  valueText: widget.valueText,
                  captionText: widget.captionText,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaterPainter extends CustomPainter {
  _WaterPainter({
    required this.level,
    required this.phase,
    required this.water,
    required this.track,
    required this.border,
    required this.label,
    this.valueText,
    this.captionText,
  });

  final double level;
  final double phase;
  final Color water;
  final Color track;
  final Color border;
  final Color label;
  final String? valueText;
  final String? captionText;

  Path _wavePath(Size s, double top, double amp, double shift) {
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 2) {
      final y = top + amp * math.sin((x / s.width) * 2 * math.pi + phase + shift);
      p.lineTo(x, y);
    }
    return p
      ..lineTo(s.width, s.height)
      ..close();
  }

  void _paintLabel(Canvas canvas, Size size, Color color) {
    if (valueText == null) return;
    final value = TextPainter(
      text: TextSpan(
        text: valueText,
        style: TextStyle(
          color: color,
          fontSize: size.width * 0.3,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final caption = captionText == null
        ? null
        : (TextPainter(
            text: TextSpan(
              text: captionText,
              style: TextStyle(
                color: color,
                fontSize: size.width * 0.075,
                fontWeight: FontWeight.w600,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout());

    final total = value.height + (caption == null ? 0 : caption.height + 6);
    final y = (size.height - total) / 2;
    value.paint(canvas, Offset((size.width - value.width) / 2, y));
    caption?.paint(
      canvas,
      Offset((size.width - caption.width) / 2, y + value.height + 6),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circle = Path()..addOval(rect);

    canvas.drawPath(circle, Paint()..color = track);
    _paintLabel(canvas, size, label);

    canvas.save();
    canvas.clipPath(circle);

    final top = size.height * (1 - level);
    // La ola se calma cuando está casi vacío o casi lleno.
    final amp =
        size.height *
        0.035 *
        math.min(1.0, level * 6) *
        math.min(1.0, (1 - level) * 6);

    final back = _wavePath(size, top, amp * 0.8, math.pi);
    final front = _wavePath(size, top, amp, 0);

    canvas.drawPath(back, Paint()..color = water.withValues(alpha: 0.45));
    canvas.drawPath(
      front,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(water, Colors.white, 0.25)!, water],
        ).createShader(rect),
    );

    // Número en blanco solo donde hay agua.
    canvas.save();
    canvas.clipPath(Path.combine(PathOperation.union, back, front));
    _paintLabel(canvas, size, Colors.white);
    canvas.restore();

    canvas.restore();

    canvas.drawCircle(
      rect.center,
      size.width / 2 - size.width * 0.01,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(_WaterPainter old) =>
      old.level != level ||
      old.phase != phase ||
      old.water != water ||
      old.track != track ||
      old.label != label ||
      old.valueText != valueText ||
      old.captionText != captionText;
}