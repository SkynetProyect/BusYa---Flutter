abstract class RutaParaderoInterface {
  final int? id;
  final int? idRuta;
  final int? idParadero;
  final int ordenSecuencia;

  RutaParaderoInterface({
    this.id,
    this.idRuta,
    this.idParadero,
    required this.ordenSecuencia,
  });
}
