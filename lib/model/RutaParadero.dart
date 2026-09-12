import 'package:flutter_application_1/interfaces/RutaParaderoInterface.dart';

class RutaParadero implements RutaParaderoInterface {
  @override
  final int? id;
  @override
  final int? idRuta;
  @override
  final int? idParadero;
  @override
  final int ordenSecuencia;

  RutaParadero({
    this.id,
    this.idRuta,
    this.idParadero,
    required this.ordenSecuencia,
  });
}
