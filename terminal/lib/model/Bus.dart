import 'package:flutter_application_1/interfaces/BusInterface.dart';

class Bus implements BusInterface {
  @override
  final int? id;
  @override
  final int? idRuta;
  @override
  final String placa;
  @override
  final int capacidadMaxima;
  @override
  final String? nivelOcupacion;
  @override
  final double? latitudActual;
  @override
  final double? longitudActual;
  @override
  final DateTime? ultimaActualizacionGps;

  Bus({
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
