import 'package:flutter_application_1/interfaces/ParaderoInterface.dart';

class Paradero implements ParaderoInterface {
  @override
  final int? id;
  @override
  final String nombre;
  @override
  final double latitud;
  @override
  final double longitud;
  @override
  final String? direccionReferencia;

  Paradero({
    this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccionReferencia,
  });
}
