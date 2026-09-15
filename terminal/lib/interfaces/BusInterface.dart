abstract class BusInterface {
  final int? id;
  final int? idRuta;
  final String placa;
  final int capacidadMaxima;
  final String? nivelOcupacion;
  final double? latitudActual;
  final double? longitudActual;
  final DateTime? ultimaActualizacionGps;

  BusInterface({
    this.id,
    this.idRuta,
    required this.placa,
    required this.capacidadMaxima,
    this.nivelOcupacion,
    this.latitudActual,
    this.longitudActual,
    this.ultimaActualizacionGps,
  });
}
