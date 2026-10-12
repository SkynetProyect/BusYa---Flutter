import 'package:audioplayers/audioplayers.dart' show AudioPlayer, AssetSource;
import 'package:flutter_application_1/model/Bus.dart' show Bus;
import 'package:flutter_application_1/service/notification_service.dart'
    show NotificationService;
import 'package:latlong2/latlong.dart' as latlong;

/// Decide cuándo avisar al usuario de que un bus está cerca
/// (sonido + notificación) y evita alertas repetidas por bus.
class BusProximityAlertService {
  /// Distancia (m) a partir de la cual se considera "cerca".
  static const double distanceMeters = 1000;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final Set<int> _alertedBusIds = {};
  static const latlong.Distance _distance = latlong.Distance();

  /// Evalúa un bus; retorna true si se disparó una alerta NUEVA.
  /// Si el bus se aleja, se rearma para un próximo acercamiento.
  bool evaluate(Bus bus, latlong.LatLng busPos, latlong.LatLng userPos) {
    final id = bus.id;
    if (id == null) return false;

    final meters = _distance.as(latlong.LengthUnit.Meter, userPos, busPos);
    final alreadyAlerted = _alertedBusIds.contains(id);

    if (meters <= distanceMeters && !alreadyAlerted) {
      _alertedBusIds.add(id);
      _playSound();
      NotificationService().mostrarNotificacion(
        id: id,
        titulo: 'Bus cerca de ti',
        cuerpo:
            'El bus ${bus.placa} está a menos de ${distanceMeters.toInt()} metros',
      );
      return true;
    }
    if (meters > distanceMeters && alreadyAlerted) {
      _alertedBusIds.remove(id);
    }
    return false;
  }

  /// Olvida buses que ya no pertenecen a la ruta activa.
  void retainOnly(Set<int> activeBusIds) {
    _alertedBusIds.removeWhere((id) => !activeBusIds.contains(id));
  }

  /// Limpia todo el estado (ej. al cambiar de ruta).
  void reset() => _alertedBusIds.clear();

  /// Reproduce el sonido; un fallo de audio nunca debe romper la app.
  Future<void> _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/bus_alert.mp3'));
    } catch (_) {}
  }

  /// Libera el reproductor.
  void dispose() => _audioPlayer.dispose();
}
