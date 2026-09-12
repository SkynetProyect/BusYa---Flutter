abstract class RutaInterface {
  final int? id;
  final int? idEmpresa;
  final String nombre;
  final double precioPasaje;
  final String? encodedPolyline;
  final int? distanciaMetros;
  final int? duracionSegundos;

  RutaInterface({
    this.id,
    this.idEmpresa,
    required this.nombre,
    required this.precioPasaje,
    this.encodedPolyline,
    this.distanciaMetros,
    this.duracionSegundos,
  });
}
