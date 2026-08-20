import 'package:flutter_application_1/interfaces/RutaInterface.dart';

class Ruta implements RutaInterface {
  @override
  final int? id;
  @override
  final int idEmpresa;
  @override
  final String nombre;
  @override
  final String encodedPolyline;
  @override
  final int distancia;
  @override
  final int duracion;

  Ruta({
    this.id,
    required this.idEmpresa,
    required this.nombre,
    required this.encodedPolyline,
    required this.distancia,
    required this.duracion,
  });
}
