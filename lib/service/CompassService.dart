import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Expone el azimut (0..360°, 0 = norte) del dispositivo.
/// Si el teléfono no tiene brújula, [heading] permanece en null.
class CompassService {
  /// Umbral mínimo (grados) para notificar un cambio y evitar jitter.
  static const double _minDeltaDegrees = 2;

  StreamSubscription<CompassEvent>? _subscription;

  /// Azimut actual normalizado a [0, 360). Null si no hay sensor/lectura.
  final ValueNotifier<double?> heading = ValueNotifier<double?>(null);

  /// True si el dispositivo reporta un sensor de brújula.
  bool get isAvailable => FlutterCompass.events != null;

  /// Comienza a escuchar el sensor (no hace nada si no existe).
  void start() {
    if (_subscription != null) return;
    final stream = FlutterCompass.events;
    if (stream == null) return; // Sin brújula en el dispositivo.

    _subscription = stream.listen(
      _onCompassEvent,
      onError: (e) => debugPrint('[COMPASS] error: $e'),
      cancelOnError: false,
    );
  }

  /// Pausa la escucha (ej. app en segundo plano).
  void pause() => _subscription?.pause();

  /// Reanuda la escucha tras [pause].
  void resume() => _subscription?.resume();

  /// Procesa una lectura: normaliza y filtra cambios pequeños.
  void _onCompassEvent(CompassEvent event) {
    final raw = event.heading;
    if (raw == null) return;

    final normalized = (raw % 360 + 360) % 360;
    final current = heading.value;
    if (current == null ||
        _angularDiff(current, normalized) >= _minDeltaDegrees) {
      heading.value = normalized;
    }
  }

  /// Diferencia angular absoluta más corta entre dos ángulos (0..180).
  double _angularDiff(double a, double b) {
    final d = (a - b).abs() % 360;
    return d > 180 ? 360 - d : d;
  }

  /// Libera recursos.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    heading.dispose();
  }
}
