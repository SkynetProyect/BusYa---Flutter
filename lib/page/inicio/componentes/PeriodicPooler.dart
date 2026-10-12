import 'dart:async';

/// Ejecuta una tarea de forma periódica y permite detenerla/reanudarla.
/// Encapsula el `Timer` para que la UI no gestione su ciclo de vida.
class PeriodicPoller {
  Timer? _timer;

  /// Indica si el polling está activo.
  bool get isRunning => _timer != null;

  /// Inicia el polling (reemplaza cualquier timer previo).
  void start(Duration interval, void Function() task) {
    stop();
    _timer = Timer.periodic(interval, (_) => task());
  }

  /// Detiene el polling si está activo.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
