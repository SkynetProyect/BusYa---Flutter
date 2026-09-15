import 'package:flutter_application_1/interfaces/RutaInterface.dart';

class Ruta implements RutaInterface {
  @override
  final int? id;
  @override
  final int? idEmpresa;
  @override
  final String nombre;
  @override
  final double precioPasaje;
  @override
  final String? encodedPolyline;
  @override
  final int? distanciaMetros;
  @override
  final int? duracionSegundos;

  Ruta({
    this.id,
    this.idEmpresa,
    required this.nombre,
    required this.precioPasaje,
    this.encodedPolyline,
    this.distanciaMetros,
    this.duracionSegundos,
  });
}
