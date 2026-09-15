abstract class ParaderoInterface {
  final int? id;
  final String nombre;
  final double latitud;
  final double longitud;
  final String? direccionReferencia;

  ParaderoInterface({
    this.id,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccionReferencia,
  });
}
