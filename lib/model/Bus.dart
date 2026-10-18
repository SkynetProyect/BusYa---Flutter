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

  Bus copyWith({
    int? id,
    int? idRuta,
    String? placa,
    int? capacidadMaxima,
    String? nivelOcupacion,
    double? latitudActual,
    double? longitudActual,
    DateTime? ultimaActualizacionGps,
  }) {
    return Bus(
      id: id ?? this.id,
      idRuta: idRuta ?? this.idRuta,
      placa: placa ?? this.placa,
      capacidadMaxima: capacidadMaxima ?? this.capacidadMaxima,
      nivelOcupacion: nivelOcupacion ?? this.nivelOcupacion,
      latitudActual: latitudActual ?? this.latitudActual,
      longitudActual: longitudActual ?? this.longitudActual,
      ultimaActualizacionGps:
          ultimaActualizacionGps ?? this.ultimaActualizacionGps,
    );
  }
}
