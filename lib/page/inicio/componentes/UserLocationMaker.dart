import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Marcador del usuario en el mapa.
/// - Con brújula disponible: flecha que rota según el azimut.
/// - Sin brújula: punto azul clásico.
class UserLocationMarker extends StatelessWidget {
  /// Azimut en grados (null si no hay brújula).
  final ValueListenable<double?> heading;

  const UserLocationMarker({super.key, required this.heading});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double?>(
      valueListenable: heading,
      builder: (_, value, __) =>
          value == null ? const _LocationDot() : _HeadingArrow(heading: value),
    );
  }
}

/// Punto azul con borde blanco (fallback sin brújula).
class _LocationDot extends StatelessWidget {
  const _LocationDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
      ),
    );
  }
}

/// Flecha animada que gira por el camino angular más corto
/// (evita el giro de 360° al cruzar de 359° a 1°).
class _HeadingArrow extends StatefulWidget {
  final double heading;
  const _HeadingArrow({required this.heading});

  @override
  State<_HeadingArrow> createState() => _HeadingArrowState();
}

class _HeadingArrowState extends State<_HeadingArrow> {
  /// Giros acumulados (en vueltas) para AnimatedRotation.
  late double _turns = widget.heading / 360;

  @override
  void didUpdateWidget(covariant _HeadingArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Delta más corto en (-180, 180] acumulado sobre las vueltas.
    final delta = ((widget.heading - oldWidget.heading + 540) % 360) - 180;
    _turns += delta / 360;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedRotation(
      turns: _turns,
      duration: const Duration(milliseconds: 150),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)],
        ),
        child: const Icon(Icons.navigation, color: Colors.blue, size: 32),
      ),
    );
  }
}
